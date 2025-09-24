-- Migration: 006_create_inventory_movements_table.sql
-- Description: Create inventory_movements table for transaction tracking
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- Create movement types enum
CREATE TYPE movement_type AS ENUM (
    'in',           -- Entrada (recepción, producción, ajuste positivo)
    'out',          -- Salida (venta, consumo, ajuste negativo)
    'transfer',     -- Transferencia entre ubicaciones
    'adjustment',   -- Ajuste de inventario
    'reservation',  -- Reserva de stock
    'allocation',   -- Asignación a orden
    'return',       -- Devolución
    'damage',       -- Producto dañado
    'expired',      -- Producto vencido
    'lost',         -- Producto perdido
    'found'         -- Producto encontrado
);

-- Create movement status enum
CREATE TYPE movement_status AS ENUM (
    'pending',      -- Pendiente de procesamiento
    'processing',   -- En procesamiento
    'completed',    -- Completado
    'cancelled',    -- Cancelado
    'failed'        -- Falló el procesamiento
);

-- Create inventory_movements table
CREATE TABLE inventory_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movement_number VARCHAR(50) UNIQUE NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id),
    location_id UUID NOT NULL REFERENCES locations(id),
    movement_type movement_type NOT NULL,
    movement_status movement_status DEFAULT 'completed',
    quantity DECIMAL(12,3) NOT NULL,
    unit_cost DECIMAL(12,4),
    total_cost DECIMAL(15,2) GENERATED ALWAYS AS (ABS(quantity) * COALESCE(unit_cost, 0)) STORED,
    reference_type VARCHAR(50), -- 'purchase_order', 'sales_order', 'transfer_order', etc.
    reference_id UUID,
    reference_number VARCHAR(50),
    batch_number VARCHAR(50),
    lot_number VARCHAR(50),
    serial_number VARCHAR(100),
    expiry_date DATE,
    manufacture_date DATE,
    destination_location_id UUID REFERENCES locations(id), -- For transfers
    reason_code VARCHAR(20),
    notes TEXT,
    external_document_number VARCHAR(50),
    external_document_date DATE,
    supplier_id UUID, -- Will be added when suppliers table is created
    customer_id UUID, -- Will be added when customers table is created
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_by UUID NOT NULL REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    reversed_by UUID REFERENCES users(id),
    reversed_at TIMESTAMP,
    reversal_reason TEXT,
    parent_movement_id UUID REFERENCES inventory_movements(id), -- For reversals
    tags JSONB,
    custom_fields JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_inventory_movements_movement_number ON inventory_movements(movement_number);
CREATE INDEX idx_inventory_movements_product_id ON inventory_movements(product_id);
CREATE INDEX idx_inventory_movements_location_id ON inventory_movements(location_id);
CREATE INDEX idx_inventory_movements_movement_type ON inventory_movements(movement_type);
CREATE INDEX idx_inventory_movements_movement_status ON inventory_movements(movement_status);
CREATE INDEX idx_inventory_movements_processed_at ON inventory_movements(processed_at);
CREATE INDEX idx_inventory_movements_processed_by ON inventory_movements(processed_by);
CREATE INDEX idx_inventory_movements_reference ON inventory_movements(reference_type, reference_id);
CREATE INDEX idx_inventory_movements_reference_number ON inventory_movements(reference_number);
CREATE INDEX idx_inventory_movements_batch_number ON inventory_movements(batch_number);
CREATE INDEX idx_inventory_movements_lot_number ON inventory_movements(lot_number);
CREATE INDEX idx_inventory_movements_serial_number ON inventory_movements(serial_number);
CREATE INDEX idx_inventory_movements_expiry_date ON inventory_movements(expiry_date);
CREATE INDEX idx_inventory_movements_destination_location_id ON inventory_movements(destination_location_id);

-- Composite indexes for common queries
CREATE INDEX idx_inventory_movements_product_date ON inventory_movements(product_id, processed_at DESC);
CREATE INDEX idx_inventory_movements_location_date ON inventory_movements(location_id, processed_at DESC);
CREATE INDEX idx_inventory_movements_type_date ON inventory_movements(movement_type, processed_at DESC);

-- Create trigger for updated_at
CREATE TRIGGER update_inventory_movements_updated_at 
    BEFORE UPDATE ON inventory_movements 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to generate movement numbers
CREATE OR REPLACE FUNCTION generate_movement_number()
RETURNS TRIGGER AS $$
DECLARE
    prefix VARCHAR(10);
    sequence_num INTEGER;
    new_number VARCHAR(50);
BEGIN
    -- Set prefix based on movement type
    prefix := CASE NEW.movement_type
        WHEN 'in' THEN 'IN'
        WHEN 'out' THEN 'OUT'
        WHEN 'transfer' THEN 'TRF'
        WHEN 'adjustment' THEN 'ADJ'
        WHEN 'reservation' THEN 'RES'
        WHEN 'allocation' THEN 'ALL'
        WHEN 'return' THEN 'RET'
        WHEN 'damage' THEN 'DMG'
        WHEN 'expired' THEN 'EXP'
        WHEN 'lost' THEN 'LST'
        WHEN 'found' THEN 'FND'
        ELSE 'MOV'
    END;
    
    -- Get next sequence number for today
    SELECT COALESCE(MAX(CAST(SUBSTRING(movement_number FROM LENGTH(prefix || '-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-') + 1) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM inventory_movements
    WHERE movement_number LIKE prefix || '-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-%';
    
    -- Generate new movement number
    new_number := prefix || '-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.movement_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for movement number generation
CREATE TRIGGER generate_movement_number_trigger
    BEFORE INSERT ON inventory_movements
    FOR EACH ROW
    WHEN (NEW.movement_number IS NULL)
    EXECUTE FUNCTION generate_movement_number();

-- Function to update stock levels
CREATE OR REPLACE FUNCTION update_stock_levels_from_movement()
RETURNS TRIGGER AS $$
DECLARE
    stock_change DECIMAL(12,3);
    dest_stock_change DECIMAL(12,3);
BEGIN
    -- Only process completed movements
    IF NEW.movement_status != 'completed' THEN
        RETURN NEW;
    END IF;
    
    -- Calculate stock change based on movement type
    stock_change := CASE NEW.movement_type
        WHEN 'in', 'return', 'found' THEN NEW.quantity
        WHEN 'out', 'damage', 'expired', 'lost' THEN -NEW.quantity
        WHEN 'transfer' THEN -NEW.quantity
        WHEN 'adjustment' THEN NEW.quantity -- Can be positive or negative
        ELSE 0
    END;
    
    -- Update source location stock
    IF stock_change != 0 THEN
        INSERT INTO stock_levels (product_id, location_id, quantity, last_cost, average_cost, updated_by)
        VALUES (NEW.product_id, NEW.location_id, stock_change, NEW.unit_cost, NEW.unit_cost, NEW.processed_by)
        ON CONFLICT (product_id, location_id)
        DO UPDATE SET
            quantity = stock_levels.quantity + stock_change,
            last_cost = COALESCE(NEW.unit_cost, stock_levels.last_cost),
            average_cost = CASE 
                WHEN NEW.unit_cost IS NOT NULL AND stock_change > 0 THEN
                    ((stock_levels.quantity * COALESCE(stock_levels.average_cost, 0)) + (stock_change * NEW.unit_cost)) / 
                    NULLIF(stock_levels.quantity + stock_change, 0)
                ELSE stock_levels.average_cost
            END,
            updated_at = CURRENT_TIMESTAMP,
            updated_by = NEW.processed_by;
    END IF;
    
    -- Update destination location stock for transfers
    IF NEW.movement_type = 'transfer' AND NEW.destination_location_id IS NOT NULL THEN
        dest_stock_change := NEW.quantity;
        
        INSERT INTO stock_levels (product_id, location_id, quantity, last_cost, average_cost, updated_by)
        VALUES (NEW.product_id, NEW.destination_location_id, dest_stock_change, NEW.unit_cost, NEW.unit_cost, NEW.processed_by)
        ON CONFLICT (product_id, location_id)
        DO UPDATE SET
            quantity = stock_levels.quantity + dest_stock_change,
            last_cost = COALESCE(NEW.unit_cost, stock_levels.last_cost),
            average_cost = CASE 
                WHEN NEW.unit_cost IS NOT NULL THEN
                    ((stock_levels.quantity * COALESCE(stock_levels.average_cost, 0)) + (dest_stock_change * NEW.unit_cost)) / 
                    NULLIF(stock_levels.quantity + dest_stock_change, 0)
                ELSE stock_levels.average_cost
            END,
            updated_at = CURRENT_TIMESTAMP,
            updated_by = NEW.processed_by;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for stock level updates
CREATE TRIGGER update_stock_levels_from_movement_trigger
    AFTER INSERT ON inventory_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_stock_levels_from_movement();

-- Function to validate movement data
CREATE OR REPLACE FUNCTION validate_movement_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate quantity is not zero
    IF NEW.quantity = 0 THEN
        RAISE EXCEPTION 'Movement quantity cannot be zero';
    END IF;
    
    -- Validate transfer has destination location
    IF NEW.movement_type = 'transfer' AND NEW.destination_location_id IS NULL THEN
        RAISE EXCEPTION 'Transfer movements must have a destination location';
    END IF;
    
    -- Validate transfer destination is different from source
    IF NEW.movement_type = 'transfer' AND NEW.location_id = NEW.destination_location_id THEN
        RAISE EXCEPTION 'Transfer source and destination locations must be different';
    END IF;
    
    -- Validate expiry date is in the future for incoming items
    IF NEW.movement_type = 'in' AND NEW.expiry_date IS NOT NULL AND NEW.expiry_date <= CURRENT_DATE THEN
        RAISE EXCEPTION 'Cannot receive expired products';
    END IF;
    
    -- Validate unit cost is positive for incoming movements
    IF NEW.movement_type IN ('in', 'return', 'found') AND NEW.unit_cost IS NOT NULL AND NEW.unit_cost < 0 THEN
        RAISE EXCEPTION 'Unit cost must be positive for incoming movements';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for movement validation
CREATE TRIGGER validate_movement_data_trigger
    BEFORE INSERT OR UPDATE ON inventory_movements
    FOR EACH ROW
    EXECUTE FUNCTION validate_movement_data();

-- Add constraints
ALTER TABLE inventory_movements ADD CONSTRAINT chk_inventory_movements_quantity_not_zero 
    CHECK (quantity != 0);

ALTER TABLE inventory_movements ADD CONSTRAINT chk_inventory_movements_unit_cost_positive 
    CHECK (unit_cost IS NULL OR unit_cost >= 0);

-- Add comments
COMMENT ON TABLE inventory_movements IS 'All inventory transactions and movements';
COMMENT ON COLUMN inventory_movements.movement_number IS 'Unique movement identifier (auto-generated)';
COMMENT ON COLUMN inventory_movements.movement_type IS 'Type of inventory movement';
COMMENT ON COLUMN inventory_movements.movement_status IS 'Processing status of the movement';
COMMENT ON COLUMN inventory_movements.quantity IS 'Quantity moved (positive for increases, negative for decreases in adjustments)';
COMMENT ON COLUMN inventory_movements.unit_cost IS 'Cost per unit for this movement';
COMMENT ON COLUMN inventory_movements.total_cost IS 'Computed: ABS(quantity) * unit_cost';
COMMENT ON COLUMN inventory_movements.reference_type IS 'Type of source document';
COMMENT ON COLUMN inventory_movements.reference_id IS 'ID of source document';
COMMENT ON COLUMN inventory_movements.batch_number IS 'Manufacturing batch number';
COMMENT ON COLUMN inventory_movements.lot_number IS 'Lot tracking number';
COMMENT ON COLUMN inventory_movements.serial_number IS 'Serial number for serialized items';
COMMENT ON COLUMN inventory_movements.destination_location_id IS 'Destination location for transfers';
COMMENT ON COLUMN inventory_movements.reason_code IS 'Standardized reason code for the movement';
COMMENT ON COLUMN inventory_movements.parent_movement_id IS 'Original movement ID for reversals';

-- Create view for movement summary
CREATE VIEW movement_summary AS
SELECT 
    DATE_TRUNC('day', processed_at) as movement_date,
    movement_type,
    location_id,
    l.name as location_name,
    COUNT(*) as movement_count,
    SUM(ABS(quantity)) as total_quantity,
    SUM(total_cost) as total_value,
    COUNT(DISTINCT product_id) as unique_products
FROM inventory_movements im
JOIN locations l ON im.location_id = l.id
WHERE movement_status = 'completed'
GROUP BY DATE_TRUNC('day', processed_at), movement_type, location_id, l.name
ORDER BY movement_date DESC, movement_type;

COMMENT ON VIEW movement_summary IS 'Daily summary of inventory movements by type and location';

-- Migration completed successfully
SELECT 'Migration 006_create_inventory_movements_table.sql completed successfully' as status;