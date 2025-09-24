-- Migration: 010_create_triggers.sql
-- Description: Create advanced triggers for business logic and data integrity
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- ==================== AUDIT TRIGGERS ====================

-- Create audit log table
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(50) NOT NULL,
    record_id UUID NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    user_id UUID REFERENCES users(id),
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for audit log
CREATE INDEX idx_audit_log_table_name ON audit_log(table_name);
CREATE INDEX idx_audit_log_record_id ON audit_log(record_id);
CREATE INDEX idx_audit_log_operation ON audit_log(operation);
CREATE INDEX idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at);

-- Generic audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    old_data JSONB;
    new_data JSONB;
    changed_fields TEXT[] := '{}';
    field_name TEXT;
BEGIN
    -- Get current user context (set by application)
    DECLARE
        current_user_id UUID := COALESCE(current_setting('app.current_user_id', true)::UUID, NULL);
        current_ip INET := COALESCE(current_setting('app.current_ip', true)::INET, NULL);
        current_user_agent TEXT := COALESCE(current_setting('app.current_user_agent', true), NULL);
        current_session_id TEXT := COALESCE(current_setting('app.current_session_id', true), NULL);
    BEGIN
        -- Handle different operations
        IF TG_OP = 'DELETE' THEN
            old_data := to_jsonb(OLD);
            new_data := NULL;
        ELSIF TG_OP = 'INSERT' THEN
            old_data := NULL;
            new_data := to_jsonb(NEW);
        ELSIF TG_OP = 'UPDATE' THEN
            old_data := to_jsonb(OLD);
            new_data := to_jsonb(NEW);
            
            -- Identify changed fields
            FOR field_name IN SELECT key FROM jsonb_each(old_data) LOOP
                IF old_data->field_name IS DISTINCT FROM new_data->field_name THEN
                    changed_fields := array_append(changed_fields, field_name);
                END IF;
            END LOOP;
        END IF;
        
        -- Insert audit record
        INSERT INTO audit_log (
            table_name, record_id, operation, old_values, new_values, 
            changed_fields, user_id, ip_address, user_agent, session_id
        ) VALUES (
            TG_TABLE_NAME,
            COALESCE((new_data->>'id')::UUID, (old_data->>'id')::UUID),
            TG_OP,
            old_data,
            new_data,
            changed_fields,
            current_user_id,
            current_ip,
            current_user_agent,
            current_session_id
        );
        
        -- Return appropriate record
        IF TG_OP = 'DELETE' THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
    END;
END;
$$ LANGUAGE plpgsql;

-- Create audit triggers for main tables
CREATE TRIGGER audit_users_trigger
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_products_trigger
    AFTER INSERT OR UPDATE OR DELETE ON products
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_stock_levels_trigger
    AFTER INSERT OR UPDATE OR DELETE ON stock_levels
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_suppliers_trigger
    AFTER INSERT OR UPDATE OR DELETE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- ==================== BUSINESS LOGIC TRIGGERS ====================

-- Trigger to prevent deletion of products with stock
CREATE OR REPLACE FUNCTION prevent_product_deletion_with_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if product has any stock
    IF EXISTS (
        SELECT 1 FROM stock_levels 
        WHERE product_id = OLD.id AND quantity != 0
    ) THEN
        RAISE EXCEPTION 'Cannot delete product with existing stock. Product ID: %', OLD.id;
    END IF;
    
    -- Check if product has recent movements (last 30 days)
    IF EXISTS (
        SELECT 1 FROM inventory_movements 
        WHERE product_id = OLD.id 
            AND processed_at >= CURRENT_DATE - INTERVAL '30 days'
            AND movement_status = 'completed'
    ) THEN
        RAISE EXCEPTION 'Cannot delete product with recent inventory movements. Product ID: %', OLD.id;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_product_deletion_with_stock_trigger
    BEFORE DELETE ON products
    FOR EACH ROW
    EXECUTE FUNCTION prevent_product_deletion_with_stock();

-- Trigger to update product last movement date
CREATE OR REPLACE FUNCTION update_product_last_movement()
RETURNS TRIGGER AS $$
BEGIN
    -- Update product's last movement tracking
    UPDATE products 
    SET updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.product_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_product_last_movement_trigger
    AFTER INSERT ON inventory_movements
    FOR EACH ROW
    WHEN (NEW.movement_status = 'completed')
    EXECUTE FUNCTION update_product_last_movement();

-- ==================== NOTIFICATION TRIGGERS ====================

-- Create notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    recipient_user_id UUID REFERENCES users(id),
    recipient_role VARCHAR(20),
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    is_sent BOOLEAN DEFAULT false,
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for notifications
CREATE INDEX idx_notifications_recipient_user_id ON notifications(recipient_user_id);
CREATE INDEX idx_notifications_recipient_role ON notifications(recipient_role);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_is_sent ON notifications(is_sent);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Function to create notifications
CREATE OR REPLACE FUNCTION create_notification(
    p_type VARCHAR(50),
    p_title VARCHAR(255),
    p_message TEXT,
    p_user_id UUID DEFAULT NULL,
    p_role VARCHAR(20) DEFAULT NULL,
    p_data JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO notifications (
        notification_type, title, message, recipient_user_id, 
        recipient_role, data, expires_at
    ) VALUES (
        p_type, p_title, p_message, p_user_id, 
        p_role, p_data, CURRENT_TIMESTAMP + INTERVAL '30 days'
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create notifications for critical alerts
CREATE OR REPLACE FUNCTION create_alert_notifications()
RETURNS TRIGGER AS $$
DECLARE
    product_name TEXT;
    location_name TEXT;
    notification_title TEXT;
    notification_message TEXT;
BEGIN
    -- Only create notifications for critical and high severity alerts
    IF NEW.severity NOT IN ('critical', 'high') OR NEW.auto_generated = false THEN
        RETURN NEW;
    END IF;
    
    -- Get product and location names
    SELECT p.name INTO product_name FROM products p WHERE p.id = NEW.product_id;
    SELECT l.name INTO location_name FROM locations l WHERE l.id = NEW.location_id;
    
    -- Create notification title and message
    notification_title := CASE NEW.alert_type
        WHEN 'out_of_stock' THEN 'Producto Sin Stock'
        WHEN 'low_stock' THEN 'Stock Bajo'
        WHEN 'expired' THEN 'Producto Vencido'
        WHEN 'expiry_warning' THEN 'Producto Próximo a Vencer'
        ELSE 'Alerta de Inventario'
    END;
    
    notification_message := NEW.message || 
        CASE WHEN product_name IS NOT NULL THEN ' - Producto: ' || product_name ELSE '' END ||
        CASE WHEN location_name IS NOT NULL THEN ' - Ubicación: ' || location_name ELSE '' END;
    
    -- Create notification for managers and admins
    PERFORM create_notification(
        'inventory_alert',
        notification_title,
        notification_message,
        NULL, -- Send to role, not specific user
        'manager', -- Send to managers
        jsonb_build_object(
            'alert_id', NEW.id,
            'alert_type', NEW.alert_type,
            'product_id', NEW.product_id,
            'location_id', NEW.location_id,
            'severity', NEW.severity
        )
    );
    
    -- Also send to admins for critical alerts
    IF NEW.severity = 'critical' THEN
        PERFORM create_notification(
            'inventory_alert',
            notification_title,
            notification_message,
            NULL,
            'admin',
            jsonb_build_object(
                'alert_id', NEW.id,
                'alert_type', NEW.alert_type,
                'product_id', NEW.product_id,
                'location_id', NEW.location_id,
                'severity', NEW.severity
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_alert_notifications_trigger
    AFTER INSERT ON alerts
    FOR EACH ROW
    EXECUTE FUNCTION create_alert_notifications();

-- ==================== DATA VALIDATION TRIGGERS ====================

-- Trigger to validate stock level changes
CREATE OR REPLACE FUNCTION validate_stock_level_changes()
RETURNS TRIGGER AS $$
DECLARE
    location_allows_negative BOOLEAN;
    product_is_trackable BOOLEAN;
BEGIN
    -- Check if product is trackable
    SELECT is_trackable INTO product_is_trackable 
    FROM products 
    WHERE id = NEW.product_id;
    
    IF NOT product_is_trackable THEN
        RAISE EXCEPTION 'Cannot manage stock for non-trackable product';
    END IF;
    
    -- Check location's negative stock policy
    SELECT allows_negative_stock INTO location_allows_negative 
    FROM locations 
    WHERE id = NEW.location_id;
    
    -- Validate negative stock
    IF NEW.quantity < 0 AND NOT location_allows_negative THEN
        RAISE EXCEPTION 'Negative stock not allowed at location: %', 
            (SELECT name FROM locations WHERE id = NEW.location_id);
    END IF;
    
    -- Validate reserved quantity
    IF NEW.reserved_quantity > NEW.quantity THEN
        RAISE EXCEPTION 'Reserved quantity (%) cannot exceed total quantity (%)', 
            NEW.reserved_quantity, NEW.quantity;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_stock_level_changes_trigger
    BEFORE INSERT OR UPDATE ON stock_levels
    FOR EACH ROW
    EXECUTE FUNCTION validate_stock_level_changes();

-- ==================== PERFORMANCE TRIGGERS ====================

-- Trigger to update supplier performance metrics
CREATE OR REPLACE FUNCTION update_supplier_performance()
RETURNS TRIGGER AS $$
BEGIN
    -- Update supplier's last order date and totals
    IF NEW.supplier_id IS NOT NULL AND NEW.movement_type = 'in' AND NEW.movement_status = 'completed' THEN
        UPDATE suppliers 
        SET 
            last_order_date = CURRENT_DATE,
            total_orders_count = total_orders_count + 1,
            total_orders_value = total_orders_value + COALESCE(NEW.total_cost, 0),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.supplier_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_supplier_performance_trigger
    AFTER INSERT ON inventory_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_supplier_performance();

-- ==================== CLEANUP TRIGGERS ====================

-- Trigger to clean up old audit logs
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete audit logs older than 2 years
    DELETE FROM audit_log 
    WHERE created_at < CURRENT_DATE - INTERVAL '2 years';
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger that runs daily to clean up old data
-- Note: This would typically be handled by a scheduled job, but included for completeness
CREATE OR REPLACE FUNCTION schedule_cleanup()
RETURNS void AS $$
BEGIN
    -- This function would be called by a scheduler
    -- Clean up old audit logs
    DELETE FROM audit_log WHERE created_at < CURRENT_DATE - INTERVAL '2 years';
    
    -- Clean up old notifications
    DELETE FROM notifications WHERE expires_at < CURRENT_TIMESTAMP;
    
    -- Clean up resolved alerts older than 6 months
    DELETE FROM alerts 
    WHERE status IN ('resolved', 'dismissed') 
        AND updated_at < CURRENT_DATE - INTERVAL '6 months';
    
    RAISE NOTICE 'Cleanup completed at %', CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- ==================== SECURITY TRIGGERS ====================

-- Trigger to log sensitive operations
CREATE OR REPLACE FUNCTION log_sensitive_operations()
RETURNS TRIGGER AS $$
BEGIN
    -- Log user role changes
    IF TG_TABLE_NAME = 'users' AND OLD.role IS DISTINCT FROM NEW.role THEN
        INSERT INTO audit_log (
            table_name, record_id, operation, old_values, new_values,
            changed_fields, created_at
        ) VALUES (
            'users_role_change',
            NEW.id,
            'ROLE_CHANGE',
            jsonb_build_object('old_role', OLD.role),
            jsonb_build_object('new_role', NEW.role),
            ARRAY['role'],
            CURRENT_TIMESTAMP
        );
    END IF;
    
    -- Log user activation/deactivation
    IF TG_TABLE_NAME = 'users' AND OLD.is_active IS DISTINCT FROM NEW.is_active THEN
        INSERT INTO audit_log (
            table_name, record_id, operation, old_values, new_values,
            changed_fields, created_at
        ) VALUES (
            'users_status_change',
            NEW.id,
            'STATUS_CHANGE',
            jsonb_build_object('old_status', OLD.is_active),
            jsonb_build_object('new_status', NEW.is_active),
            ARRAY['is_active'],
            CURRENT_TIMESTAMP
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_sensitive_operations_trigger
    AFTER UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION log_sensitive_operations();

-- ==================== HELPER FUNCTIONS ====================

-- Function to get trigger information
CREATE OR REPLACE FUNCTION get_trigger_info()
RETURNS TABLE(
    trigger_name TEXT,
    table_name TEXT,
    trigger_event TEXT,
    trigger_timing TEXT,
    function_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tgname::TEXT as trigger_name,
        c.relname::TEXT as table_name,
        CASE t.tgtype & 28
            WHEN 4 THEN 'INSERT'
            WHEN 8 THEN 'DELETE'
            WHEN 16 THEN 'UPDATE'
            WHEN 12 THEN 'INSERT OR DELETE'
            WHEN 20 THEN 'INSERT OR UPDATE'
            WHEN 24 THEN 'UPDATE OR DELETE'
            WHEN 28 THEN 'INSERT OR UPDATE OR DELETE'
        END::TEXT as trigger_event,
        CASE t.tgtype & 2
            WHEN 0 THEN 'AFTER'
            WHEN 2 THEN 'BEFORE'
        END::TEXT as trigger_timing,
        p.proname::TEXT as function_name
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_proc p ON t.tgfoid = p.oid
    WHERE c.relkind = 'r'
        AND NOT t.tgisinternal
        AND c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    ORDER BY c.relname, t.tgname;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_trigger_info() IS 'Returns information about all triggers in the public schema';

-- Function to disable/enable triggers for maintenance
CREATE OR REPLACE FUNCTION toggle_triggers(
    p_table_name TEXT,
    p_enable BOOLEAN DEFAULT true
)
RETURNS void AS $$
DECLARE
    trigger_cmd TEXT;
BEGIN
    IF p_enable THEN
        trigger_cmd := 'ENABLE TRIGGER ALL ON ' || p_table_name;
        RAISE NOTICE 'Enabling all triggers on table: %', p_table_name;
    ELSE
        trigger_cmd := 'DISABLE TRIGGER ALL ON ' || p_table_name;
        RAISE NOTICE 'Disabling all triggers on table: %', p_table_name;
    END IF;
    
    EXECUTE trigger_cmd;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION toggle_triggers(TEXT, BOOLEAN) IS 'Enable or disable all triggers on a specific table';

-- ==================== COMMENTS ====================

COMMENT ON TABLE audit_log IS 'Comprehensive audit trail for all data changes';
COMMENT ON TABLE notifications IS 'System notifications for users and roles';

COMMENT ON FUNCTION audit_trigger_function() IS 'Generic audit trigger function for tracking data changes';
COMMENT ON FUNCTION create_notification(VARCHAR, VARCHAR, TEXT, UUID, VARCHAR, JSONB) IS 'Creates system notifications for users or roles';
COMMENT ON FUNCTION schedule_cleanup() IS 'Scheduled cleanup function for old data';

-- Migration completed successfully
SELECT 'Migration 010_create_triggers.sql completed successfully' as status;
SELECT 'Created comprehensive trigger system with audit logging and notifications' as summary;