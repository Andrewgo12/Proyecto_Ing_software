-- Migration: 005_create_stock_levels_table.sql
-- Description: Create stock_levels table for inventory tracking
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- Create stock_levels table
CREATE TABLE stock_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    quantity DECIMAL(12,3) NOT NULL DEFAULT 0,
    reserved_quantity DECIMAL(12,3) NOT NULL DEFAULT 0,
    available_quantity DECIMAL(12,3) GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
    allocated_quantity DECIMAL(12,3) NOT NULL DEFAULT 0,
    on_order_quantity DECIMAL(12,3) NOT NULL DEFAULT 0,
    min_stock DECIMAL(12,3),
    max_stock DECIMAL(12,3),
    reorder_point DECIMAL(12,3),
    reorder_quantity DECIMAL(12,3),
    safety_stock DECIMAL(12,3) DEFAULT 0,
    abc_classification CHAR(1) CHECK (abc_classification IN ('A', 'B', 'C')),
    velocity_classification VARCHAR(10) CHECK (velocity_classification IN ('fast', 'medium', 'slow', 'dead')),
    last_movement_date TIMESTAMP,
    last_count_date TIMESTAMP,
    last_count_quantity DECIMAL(12,3),
    last_count_variance DECIMAL(12,3),
    last_count_user_id UUID REFERENCES users(id),
    cycle_count_due_date DATE,
    lot_tracking BOOLEAN DEFAULT false,
    serial_tracking BOOLEAN DEFAULT false,
    expiry_tracking BOOLEAN DEFAULT false,
    cost_method VARCHAR(10) DEFAULT 'FIFO' CHECK (cost_method IN ('FIFO', 'LIFO', 'AVERAGE', 'SPECIFIC')),
    average_cost DECIMAL(12,4),
    last_cost DECIMAL(12,4),
    total_value DECIMAL(15,2) GENERATED ALWAYS AS (quantity * COALESCE(average_cost, 0)) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create unique constraint for product-location combination
ALTER TABLE stock_levels ADD CONSTRAINT uk_stock_levels_product_location 
    UNIQUE (product_id, location_id);

-- Create indexes for performance
CREATE INDEX idx_stock_levels_product_id ON stock_levels(product_id);
CREATE INDEX idx_stock_levels_location_id ON stock_levels(location_id);
CREATE INDEX idx_stock_levels_quantity ON stock_levels(quantity);
CREATE INDEX idx_stock_levels_available_quantity ON stock_levels(available_quantity);
CREATE INDEX idx_stock_levels_last_movement_date ON stock_levels(last_movement_date);
CREATE INDEX idx_stock_levels_abc_classification ON stock_levels(abc_classification);
CREATE INDEX idx_stock_levels_velocity_classification ON stock_levels(velocity_classification);
CREATE INDEX idx_stock_levels_cycle_count_due_date ON stock_levels(cycle_count_due_date);

-- Composite indexes for common queries
CREATE INDEX idx_stock_levels_low_stock ON stock_levels(product_id, location_id) 
    WHERE quantity <= COALESCE(min_stock, 0);

CREATE INDEX idx_stock_levels_negative ON stock_levels(product_id, location_id) 
    WHERE quantity < 0;

CREATE INDEX idx_stock_levels_overstock ON stock_levels(product_id, location_id) 
    WHERE max_stock IS NOT NULL AND quantity > max_stock;

-- Create trigger for updated_at
CREATE TRIGGER update_stock_levels_updated_at 
    BEFORE UPDATE ON stock_levels 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to validate stock quantities
CREATE OR REPLACE FUNCTION validate_stock_quantities()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate reserved quantity doesn't exceed total quantity
    IF NEW.reserved_quantity > NEW.quantity THEN
        RAISE EXCEPTION 'Reserved quantity (%) cannot exceed total quantity (%)', 
            NEW.reserved_quantity, NEW.quantity;
    END IF;
    
    -- Validate allocated quantity doesn't exceed available quantity
    IF NEW.allocated_quantity > (NEW.quantity - NEW.reserved_quantity) THEN
        RAISE EXCEPTION 'Allocated quantity (%) cannot exceed available quantity (%)', 
            NEW.allocated_quantity, (NEW.quantity - NEW.reserved_quantity);
    END IF;
    
    -- Validate min/max stock relationship
    IF NEW.min_stock IS NOT NULL AND NEW.max_stock IS NOT NULL AND NEW.min_stock > NEW.max_stock THEN
        RAISE EXCEPTION 'Minimum stock (%) cannot exceed maximum stock (%)', 
            NEW.min_stock, NEW.max_stock;
    END IF;
    
    -- Validate reorder point
    IF NEW.reorder_point IS NOT NULL AND NEW.min_stock IS NOT NULL AND NEW.reorder_point < NEW.min_stock THEN
        RAISE EXCEPTION 'Reorder point (%) should not be less than minimum stock (%)', 
            NEW.reorder_point, NEW.min_stock;
    END IF;
    
    -- Check if location allows negative stock
    IF NEW.quantity < 0 THEN
        IF NOT EXISTS (
            SELECT 1 FROM locations 
            WHERE id = NEW.location_id AND allows_negative_stock = true
        ) THEN
            RAISE EXCEPTION 'Negative stock not allowed at this location';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for stock validation
CREATE TRIGGER validate_stock_quantities_trigger
    BEFORE INSERT OR UPDATE ON stock_levels
    FOR EACH ROW
    EXECUTE FUNCTION validate_stock_quantities();

-- Function to update movement date on quantity change
CREATE OR REPLACE FUNCTION update_last_movement_date()
RETURNS TRIGGER AS $$
BEGIN
    -- Update last movement date if quantity changed
    IF OLD.quantity IS DISTINCT FROM NEW.quantity THEN
        NEW.last_movement_date = CURRENT_TIMESTAMP;
    END IF;
    
    -- Calculate variance if count quantity is provided
    IF NEW.last_count_quantity IS NOT NULL AND OLD.last_count_quantity IS DISTINCT FROM NEW.last_count_quantity THEN
        NEW.last_count_variance = NEW.last_count_quantity - OLD.quantity;
        NEW.last_count_date = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for movement date updates
CREATE TRIGGER update_last_movement_date_trigger
    BEFORE UPDATE ON stock_levels
    FOR EACH ROW
    EXECUTE FUNCTION update_last_movement_date();

-- Function to automatically create stock level records
CREATE OR REPLACE FUNCTION create_stock_level_for_product()
RETURNS TRIGGER AS $$
DECLARE
    default_location_id UUID;
BEGIN
    -- Get default location
    SELECT id INTO default_location_id 
    FROM locations 
    WHERE is_default = true AND is_active = true 
    LIMIT 1;
    
    -- Create stock level record for default location if it exists
    IF default_location_id IS NOT NULL THEN
        INSERT INTO stock_levels (
            product_id, 
            location_id, 
            quantity,
            min_stock,
            max_stock,
            reorder_point,
            reorder_quantity,
            created_by
        ) VALUES (
            NEW.id,
            default_location_id,
            0,
            NEW.min_stock_level,
            NEW.max_stock_level,
            NEW.reorder_point,
            NEW.reorder_quantity,
            NEW.created_by
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-create stock levels for new products
CREATE TRIGGER create_stock_level_for_product_trigger
    AFTER INSERT ON products
    FOR EACH ROW
    WHEN (NEW.is_trackable = true)
    EXECUTE FUNCTION create_stock_level_for_product();

-- Add comments
COMMENT ON TABLE stock_levels IS 'Current stock levels for each product at each location';
COMMENT ON COLUMN stock_levels.quantity IS 'Total quantity on hand';
COMMENT ON COLUMN stock_levels.reserved_quantity IS 'Quantity reserved for orders/allocations';
COMMENT ON COLUMN stock_levels.available_quantity IS 'Computed: quantity - reserved_quantity';
COMMENT ON COLUMN stock_levels.allocated_quantity IS 'Quantity allocated to specific orders';
COMMENT ON COLUMN stock_levels.on_order_quantity IS 'Quantity on purchase orders';
COMMENT ON COLUMN stock_levels.abc_classification IS 'ABC analysis classification (A=high value, C=low value)';
COMMENT ON COLUMN stock_levels.velocity_classification IS 'Movement velocity classification';
COMMENT ON COLUMN stock_levels.last_count_variance IS 'Difference between physical count and system quantity';
COMMENT ON COLUMN stock_levels.cycle_count_due_date IS 'Next scheduled cycle count date';
COMMENT ON COLUMN stock_levels.cost_method IS 'Inventory costing method';
COMMENT ON COLUMN stock_levels.average_cost IS 'Weighted average cost per unit';
COMMENT ON COLUMN stock_levels.total_value IS 'Computed: quantity * average_cost';

-- Create view for stock alerts
CREATE VIEW stock_alerts AS
SELECT 
    sl.id,
    sl.product_id,
    p.sku,
    p.name as product_name,
    sl.location_id,
    l.name as location_name,
    sl.quantity,
    sl.available_quantity,
    sl.min_stock,
    sl.max_stock,
    CASE 
        WHEN sl.quantity <= 0 THEN 'OUT_OF_STOCK'
        WHEN sl.quantity <= COALESCE(sl.min_stock, 0) THEN 'LOW_STOCK'
        WHEN sl.max_stock IS NOT NULL AND sl.quantity > sl.max_stock THEN 'OVERSTOCK'
        ELSE 'NORMAL'
    END as alert_type,
    sl.last_movement_date,
    sl.updated_at
FROM stock_levels sl
JOIN products p ON sl.product_id = p.id
JOIN locations l ON sl.location_id = l.id
WHERE p.is_active = true 
    AND l.is_active = true
    AND p.is_trackable = true
    AND (
        sl.quantity <= 0 
        OR sl.quantity <= COALESCE(sl.min_stock, 0)
        OR (sl.max_stock IS NOT NULL AND sl.quantity > sl.max_stock)
    );

COMMENT ON VIEW stock_alerts IS 'View showing products with stock alerts (low, out of stock, overstock)';

-- Migration completed successfully
SELECT 'Migration 005_create_stock_levels_table.sql completed successfully' as status;