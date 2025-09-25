-- Schema: stored-procedures.sql
-- Description: Stored procedures for Sistema de Inventario PYMES
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- ==================== INVENTORY MANAGEMENT PROCEDURES ====================

-- Procedure to process inventory movement
CREATE OR REPLACE FUNCTION process_inventory_movement(
    p_product_id UUID,
    p_location_id UUID,
    p_movement_type movement_type,
    p_quantity DECIMAL(12,3),
    p_unit_cost DECIMAL(12,4) DEFAULT NULL,
    p_reference_type VARCHAR(50) DEFAULT NULL,
    p_reference_number VARCHAR(50) DEFAULT NULL,
    p_destination_location_id UUID DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_processed_by UUID DEFAULT NULL,
    p_supplier_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    movement_id UUID;
    current_stock DECIMAL(12,3);
    location_allows_negative BOOLEAN;
BEGIN
    -- Validate inputs
    IF p_product_id IS NULL OR p_location_id IS NULL OR p_quantity = 0 THEN
        RAISE EXCEPTION 'Invalid input parameters';
    END IF;
    
    -- Check if location allows negative stock for outbound movements
    IF p_movement_type IN ('out', 'transfer') THEN
        SELECT allows_negative_stock INTO location_allows_negative
        FROM locations WHERE id = p_location_id;
        
        SELECT COALESCE(quantity, 0) INTO current_stock
        FROM stock_levels 
        WHERE product_id = p_product_id AND location_id = p_location_id;
        
        IF NOT location_allows_negative AND (current_stock - ABS(p_quantity)) < 0 THEN
            RAISE EXCEPTION 'Insufficient stock. Current: %, Required: %', current_stock, ABS(p_quantity);
        END IF;
    END IF;
    
    -- Validate transfer has destination
    IF p_movement_type = 'transfer' AND p_destination_location_id IS NULL THEN
        RAISE EXCEPTION 'Transfer movements require destination location';
    END IF;
    
    -- Create movement record
    INSERT INTO inventory_movements (
        product_id, location_id, movement_type, quantity, unit_cost,
        reference_type, reference_number, destination_location_id,
        notes, processed_by, supplier_id
    ) VALUES (
        p_product_id, p_location_id, p_movement_type, p_quantity, p_unit_cost,
        p_reference_type, p_reference_number, p_destination_location_id,
        p_notes, p_processed_by, p_supplier_id
    ) RETURNING id INTO movement_id;
    
    RETURN movement_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure to adjust stock levels
CREATE OR REPLACE FUNCTION adjust_stock_level(
    p_product_id UUID,
    p_location_id UUID,
    p_new_quantity DECIMAL(12,3),
    p_reason VARCHAR(100),
    p_processed_by UUID
)
RETURNS UUID AS $$
DECLARE
    current_quantity DECIMAL(12,3);
    adjustment_quantity DECIMAL(12,3);
    movement_id UUID;
BEGIN
    -- Get current stock level
    SELECT COALESCE(quantity, 0) INTO current_quantity
    FROM stock_levels 
    WHERE product_id = p_product_id AND location_id = p_location_id;
    
    -- Calculate adjustment needed
    adjustment_quantity := p_new_quantity - current_quantity;
    
    -- Create adjustment movement
    SELECT process_inventory_movement(
        p_product_id,
        p_location_id,
        'adjustment',
        adjustment_quantity,
        NULL,
        'stock_adjustment',
        'ADJ-' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD-HH24MISS'),
        NULL,
        p_reason,
        p_processed_by,
        NULL
    ) INTO movement_id;
    
    RETURN movement_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure to transfer stock between locations
CREATE OR REPLACE FUNCTION transfer_stock(
    p_product_id UUID,
    p_from_location_id UUID,
    p_to_location_id UUID,
    p_quantity DECIMAL(12,3),
    p_reference_number VARCHAR(50) DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_processed_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    movement_id UUID;
    current_stock DECIMAL(12,3);
BEGIN
    -- Validate locations are different
    IF p_from_location_id = p_to_location_id THEN
        RAISE EXCEPTION 'Source and destination locations must be different';
    END IF;
    
    -- Check available stock
    SELECT COALESCE(available_quantity, 0) INTO current_stock
    FROM stock_levels 
    WHERE product_id = p_product_id AND location_id = p_from_location_id;
    
    IF current_stock < p_quantity THEN
        RAISE EXCEPTION 'Insufficient available stock. Available: %, Required: %', current_stock, p_quantity;
    END IF;
    
    -- Create transfer movement
    SELECT process_inventory_movement(
        p_product_id,
        p_from_location_id,
        'transfer',
        p_quantity,
        NULL,
        'transfer_order',
        COALESCE(p_reference_number, 'TR-' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD-HH24MISS')),
        p_to_location_id,
        p_notes,
        p_processed_by,
        NULL
    ) INTO movement_id;
    
    RETURN movement_id;
END;
$$ LANGUAGE plpgsql;

-- ==================== STOCK RESERVATION PROCEDURES ====================

-- Procedure to reserve stock
CREATE OR REPLACE FUNCTION reserve_stock(
    p_product_id UUID,
    p_location_id UUID,
    p_quantity DECIMAL(12,3),
    p_reference_type VARCHAR(50),
    p_reference_id UUID,
    p_reserved_by UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    available_qty DECIMAL(12,3);
BEGIN
    -- Check available quantity
    SELECT COALESCE(available_quantity, 0) INTO available_qty
    FROM stock_levels 
    WHERE product_id = p_product_id AND location_id = p_location_id;
    
    IF available_qty < p_quantity THEN
        RAISE EXCEPTION 'Insufficient available stock for reservation. Available: %, Required: %', available_qty, p_quantity;
    END IF;
    
    -- Update reserved quantity
    UPDATE stock_levels 
    SET reserved_quantity = reserved_quantity + p_quantity,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_reserved_by
    WHERE product_id = p_product_id AND location_id = p_location_id;
    
    -- Log reservation (optional: create reservation tracking table)
    INSERT INTO inventory_movements (
        product_id, location_id, movement_type, quantity,
        reference_type, reference_id, processed_by, notes
    ) VALUES (
        p_product_id, p_location_id, 'reservation', p_quantity,
        p_reference_type, p_reference_id, p_reserved_by, 'Stock reserved'
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Procedure to release stock reservation
CREATE OR REPLACE FUNCTION release_stock_reservation(
    p_product_id UUID,
    p_location_id UUID,
    p_quantity DECIMAL(12,3),
    p_reference_type VARCHAR(50),
    p_reference_id UUID,
    p_released_by UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    reserved_qty DECIMAL(12,3);
BEGIN
    -- Check reserved quantity
    SELECT COALESCE(reserved_quantity, 0) INTO reserved_qty
    FROM stock_levels 
    WHERE product_id = p_product_id AND location_id = p_location_id;
    
    IF reserved_qty < p_quantity THEN
        RAISE EXCEPTION 'Cannot release more than reserved. Reserved: %, Requested: %', reserved_qty, p_quantity;
    END IF;
    
    -- Update reserved quantity
    UPDATE stock_levels 
    SET reserved_quantity = reserved_quantity - p_quantity,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_released_by
    WHERE product_id = p_product_id AND location_id = p_location_id;
    
    -- Log reservation release
    INSERT INTO inventory_movements (
        product_id, location_id, movement_type, quantity,
        reference_type, reference_id, processed_by, notes
    ) VALUES (
        p_product_id, p_location_id, 'reservation', -p_quantity,
        p_reference_type, p_reference_id, p_released_by, 'Stock reservation released'
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ==================== REPORTING PROCEDURES ====================

-- Procedure to get stock report by location
CREATE OR REPLACE FUNCTION get_stock_report_by_location(
    p_location_id UUID DEFAULT NULL,
    p_category_id UUID DEFAULT NULL,
    p_include_zero_stock BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(
    product_id UUID,
    sku VARCHAR(50),
    product_name VARCHAR(255),
    category_name VARCHAR(100),
    location_name VARCHAR(100),
    quantity DECIMAL(12,3),
    available_quantity DECIMAL(12,3),
    reserved_quantity DECIMAL(12,3),
    unit_cost DECIMAL(12,4),
    total_value DECIMAL(15,2),
    last_movement_date TIMESTAMP,
    stock_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.sku,
        p.name,
        c.name,
        l.name,
        COALESCE(sl.quantity, 0),
        COALESCE(sl.available_quantity, 0),
        COALESCE(sl.reserved_quantity, 0),
        sl.average_cost,
        COALESCE(sl.total_value, 0),
        sl.last_movement_date,
        CASE 
            WHEN COALESCE(sl.quantity, 0) <= 0 THEN 'OUT_OF_STOCK'
            WHEN COALESCE(sl.quantity, 0) <= COALESCE(sl.min_stock, 0) THEN 'LOW_STOCK'
            WHEN sl.max_stock IS NOT NULL AND COALESCE(sl.quantity, 0) > sl.max_stock THEN 'OVERSTOCK'
            ELSE 'NORMAL'
        END
    FROM products p
    JOIN categories c ON p.category_id = c.id
    CROSS JOIN locations l
    LEFT JOIN stock_levels sl ON p.id = sl.product_id AND l.id = sl.location_id
    WHERE p.is_active = true 
        AND p.is_trackable = true
        AND l.is_active = true
        AND (p_location_id IS NULL OR l.id = p_location_id)
        AND (p_category_id IS NULL OR c.id = p_category_id)
        AND (p_include_zero_stock OR COALESCE(sl.quantity, 0) > 0)
    ORDER BY l.name, c.name, p.name;
END;
$$ LANGUAGE plpgsql;

-- Procedure to get movement history
CREATE OR REPLACE FUNCTION get_movement_history(
    p_product_id UUID DEFAULT NULL,
    p_location_id UUID DEFAULT NULL,
    p_movement_type movement_type DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE(
    movement_id UUID,
    movement_number VARCHAR(50),
    product_sku VARCHAR(50),
    product_name VARCHAR(255),
    location_name VARCHAR(100),
    movement_type movement_type,
    quantity DECIMAL(12,3),
    unit_cost DECIMAL(12,4),
    total_cost DECIMAL(15,2),
    reference_number VARCHAR(50),
    processed_at TIMESTAMP,
    processed_by_name TEXT,
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        im.id,
        im.movement_number,
        p.sku,
        p.name,
        l.name,
        im.movement_type,
        im.quantity,
        im.unit_cost,
        im.total_cost,
        im.reference_number,
        im.processed_at,
        u.first_name || ' ' || u.last_name,
        im.notes
    FROM inventory_movements im
    JOIN products p ON im.product_id = p.id
    JOIN locations l ON im.location_id = l.id
    JOIN users u ON im.processed_by = u.id
    WHERE im.movement_status = 'completed'
        AND (p_product_id IS NULL OR im.product_id = p_product_id)
        AND (p_location_id IS NULL OR im.location_id = p_location_id)
        AND (p_movement_type IS NULL OR im.movement_type = p_movement_type)
        AND (p_start_date IS NULL OR DATE(im.processed_at) >= p_start_date)
        AND (p_end_date IS NULL OR DATE(im.processed_at) <= p_end_date)
    ORDER BY im.processed_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ==================== ALERT MANAGEMENT PROCEDURES ====================

-- Procedure to create alert
CREATE OR REPLACE FUNCTION create_alert(
    p_alert_type alert_type,
    p_severity alert_severity,
    p_title VARCHAR(255),
    p_message TEXT,
    p_product_id UUID DEFAULT NULL,
    p_location_id UUID DEFAULT NULL,
    p_current_value DECIMAL(12,3) DEFAULT NULL,
    p_threshold_value DECIMAL(12,3) DEFAULT NULL,
    p_requires_action BOOLEAN DEFAULT FALSE,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    alert_id UUID;
    existing_alert_id UUID;
BEGIN
    -- Check for existing similar alert
    SELECT id INTO existing_alert_id
    FROM alerts 
    WHERE alert_type = p_alert_type
        AND status = 'active'
        AND (product_id = p_product_id OR (product_id IS NULL AND p_product_id IS NULL))
        AND (location_id = p_location_id OR (location_id IS NULL AND p_location_id IS NULL))
    LIMIT 1;
    
    -- If similar alert exists, update it instead of creating new one
    IF existing_alert_id IS NOT NULL THEN
        UPDATE alerts 
        SET current_value = p_current_value,
            threshold_value = p_threshold_value,
            message = p_message,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = existing_alert_id;
        
        RETURN existing_alert_id;
    END IF;
    
    -- Create new alert
    INSERT INTO alerts (
        alert_type, severity, title, message, product_id, location_id,
        current_value, threshold_value, requires_action, created_by
    ) VALUES (
        p_alert_type, p_severity, p_title, p_message, p_product_id, p_location_id,
        p_current_value, p_threshold_value, p_requires_action, p_created_by
    ) RETURNING id INTO alert_id;
    
    RETURN alert_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure to acknowledge alert
CREATE OR REPLACE FUNCTION acknowledge_alert(
    p_alert_id UUID,
    p_acknowledged_by UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE alerts 
    SET status = 'acknowledged',
        acknowledged_by = p_acknowledged_by,
        acknowledged_at = CURRENT_TIMESTAMP,
        resolution_notes = COALESCE(p_notes, resolution_notes),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_alert_id AND status = 'active';
    
    IF FOUND THEN
        RETURN TRUE;
    ELSE
        RAISE EXCEPTION 'Alert not found or already processed';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Procedure to resolve alert
CREATE OR REPLACE FUNCTION resolve_alert(
    p_alert_id UUID,
    p_resolved_by UUID,
    p_resolution_notes TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE alerts 
    SET status = 'resolved',
        resolved_by = p_resolved_by,
        resolved_at = CURRENT_TIMESTAMP,
        resolution_notes = p_resolution_notes,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_alert_id AND status IN ('active', 'acknowledged');
    
    IF FOUND THEN
        RETURN TRUE;
    ELSE
        RAISE EXCEPTION 'Alert not found or cannot be resolved';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ==================== MAINTENANCE PROCEDURES ====================

-- Procedure to recalculate stock levels
CREATE OR REPLACE FUNCTION recalculate_stock_levels(
    p_product_id UUID DEFAULT NULL,
    p_location_id UUID DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    rec RECORD;
    calculated_qty DECIMAL(12,3);
    records_updated INTEGER := 0;
BEGIN
    -- Loop through stock level records
    FOR rec IN 
        SELECT sl.product_id, sl.location_id, sl.quantity as current_qty
        FROM stock_levels sl
        WHERE (p_product_id IS NULL OR sl.product_id = p_product_id)
            AND (p_location_id IS NULL OR sl.location_id = p_location_id)
    LOOP
        -- Calculate quantity from movements
        SELECT COALESCE(SUM(
            CASE 
                WHEN movement_type IN ('in', 'return', 'found') THEN quantity
                WHEN movement_type IN ('out', 'damage', 'expired', 'lost') THEN -quantity
                WHEN movement_type = 'transfer' AND location_id = rec.location_id THEN -quantity
                WHEN movement_type = 'transfer' AND destination_location_id = rec.location_id THEN quantity
                WHEN movement_type = 'adjustment' THEN quantity
                ELSE 0
            END
        ), 0) INTO calculated_qty
        FROM inventory_movements
        WHERE product_id = rec.product_id 
            AND (location_id = rec.location_id OR destination_location_id = rec.location_id)
            AND movement_status = 'completed';
        
        -- Update if different
        IF calculated_qty != rec.current_qty THEN
            UPDATE stock_levels 
            SET quantity = calculated_qty,
                updated_at = CURRENT_TIMESTAMP
            WHERE product_id = rec.product_id AND location_id = rec.location_id;
            
            records_updated := records_updated + 1;
        END IF;
    END LOOP;
    
    RETURN records_updated;
END;
$$ LANGUAGE plpgsql;

-- Procedure to cleanup old data
CREATE OR REPLACE FUNCTION cleanup_old_data(
    p_audit_retention_days INTEGER DEFAULT 730,  -- 2 years
    p_notification_retention_days INTEGER DEFAULT 90,  -- 3 months
    p_resolved_alert_retention_days INTEGER DEFAULT 180  -- 6 months
)
RETURNS TABLE(
    table_name TEXT,
    records_deleted INTEGER
) AS $$
DECLARE
    audit_deleted INTEGER;
    notification_deleted INTEGER;
    alert_deleted INTEGER;
BEGIN
    -- Clean up old audit logs
    DELETE FROM audit_log 
    WHERE created_at < CURRENT_DATE - (p_audit_retention_days || ' days')::INTERVAL;
    GET DIAGNOSTICS audit_deleted = ROW_COUNT;
    
    -- Clean up old notifications
    DELETE FROM notifications 
    WHERE (expires_at < CURRENT_TIMESTAMP OR created_at < CURRENT_DATE - (p_notification_retention_days || ' days')::INTERVAL);
    GET DIAGNOSTICS notification_deleted = ROW_COUNT;
    
    -- Clean up resolved alerts
    DELETE FROM alerts 
    WHERE status IN ('resolved', 'dismissed') 
        AND updated_at < CURRENT_DATE - (p_resolved_alert_retention_days || ' days')::INTERVAL;
    GET DIAGNOSTICS alert_deleted = ROW_COUNT;
    
    -- Return results
    RETURN QUERY VALUES 
        ('audit_log', audit_deleted),
        ('notifications', notification_deleted),
        ('alerts', alert_deleted);
END;
$$ LANGUAGE plpgsql;

-- ==================== UTILITY PROCEDURES ====================

-- Procedure to get system statistics
CREATE OR REPLACE FUNCTION get_system_statistics()
RETURNS TABLE(
    metric_name TEXT,
    metric_value BIGINT,
    metric_description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'total_products'::TEXT, COUNT(*)::BIGINT, 'Total active products'::TEXT FROM products WHERE is_active = true
    UNION ALL
    SELECT 'total_locations'::TEXT, COUNT(*)::BIGINT, 'Total active locations'::TEXT FROM locations WHERE is_active = true
    UNION ALL
    SELECT 'total_suppliers'::TEXT, COUNT(*)::BIGINT, 'Total active suppliers'::TEXT FROM suppliers WHERE status = 'active'
    UNION ALL
    SELECT 'total_users'::TEXT, COUNT(*)::BIGINT, 'Total active users'::TEXT FROM users WHERE is_active = true
    UNION ALL
    SELECT 'total_stock_records'::TEXT, COUNT(*)::BIGINT, 'Total stock level records'::TEXT FROM stock_levels
    UNION ALL
    SELECT 'total_movements_30d'::TEXT, COUNT(*)::BIGINT, 'Total movements last 30 days'::TEXT 
    FROM inventory_movements WHERE processed_at >= CURRENT_DATE - INTERVAL '30 days'
    UNION ALL
    SELECT 'active_alerts'::TEXT, COUNT(*)::BIGINT, 'Active alerts'::TEXT FROM alerts WHERE status = 'active'
    UNION ALL
    SELECT 'low_stock_products'::TEXT, COUNT(*)::BIGINT, 'Products with low stock'::TEXT 
    FROM stock_levels sl JOIN products p ON sl.product_id = p.id 
    WHERE p.is_active = true AND sl.quantity <= COALESCE(sl.min_stock, 0)
    UNION ALL
    SELECT 'out_of_stock_products'::TEXT, COUNT(*)::BIGINT, 'Products out of stock'::TEXT 
    FROM stock_levels sl JOIN products p ON sl.product_id = p.id 
    WHERE p.is_active = true AND sl.quantity <= 0;
END;
$$ LANGUAGE plpgsql;

-- ==================== COMMENTS ====================

COMMENT ON FUNCTION process_inventory_movement IS 'Process a new inventory movement with validation';
COMMENT ON FUNCTION adjust_stock_level IS 'Adjust stock level to a specific quantity';
COMMENT ON FUNCTION transfer_stock IS 'Transfer stock between locations';
COMMENT ON FUNCTION reserve_stock IS 'Reserve stock for orders or allocations';
COMMENT ON FUNCTION release_stock_reservation IS 'Release previously reserved stock';
COMMENT ON FUNCTION get_stock_report_by_location IS 'Generate stock report filtered by location and category';
COMMENT ON FUNCTION get_movement_history IS 'Get movement history with filters';
COMMENT ON FUNCTION create_alert IS 'Create or update system alert';
COMMENT ON FUNCTION acknowledge_alert IS 'Acknowledge an active alert';
COMMENT ON FUNCTION resolve_alert IS 'Resolve an alert with notes';
COMMENT ON FUNCTION recalculate_stock_levels IS 'Recalculate stock levels from movement history';
COMMENT ON FUNCTION cleanup_old_data IS 'Clean up old audit logs, notifications, and resolved alerts';
COMMENT ON FUNCTION get_system_statistics IS 'Get system-wide statistics and metrics';

-- Stored procedures created successfully
SELECT 'Stored procedures created successfully' as status;
SELECT COUNT(*) || ' procedures created' as summary 
FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';