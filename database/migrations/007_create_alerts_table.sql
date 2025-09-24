-- Migration: 007_create_alerts_table.sql
-- Description: Create alerts table for inventory notifications
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- Create alert types enum
CREATE TYPE alert_type AS ENUM (
    'low_stock',        -- Stock bajo el mínimo
    'out_of_stock',     -- Sin stock
    'overstock',        -- Stock excesivo
    'expiry_warning',   -- Próximo a vencer
    'expired',          -- Producto vencido
    'slow_moving',      -- Producto de baja rotación
    'fast_moving',      -- Producto de alta rotación
    'negative_stock',   -- Stock negativo
    'cycle_count_due',  -- Conteo cíclico pendiente
    'price_change',     -- Cambio de precio
    'cost_variance',    -- Variación de costo
    'system_error'      -- Error del sistema
);

-- Create alert severity enum
CREATE TYPE alert_severity AS ENUM ('low', 'medium', 'high', 'critical');

-- Create alert status enum
CREATE TYPE alert_status AS ENUM ('active', 'acknowledged', 'resolved', 'dismissed', 'expired');

-- Create alerts table
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_code VARCHAR(20) UNIQUE NOT NULL,
    alert_type alert_type NOT NULL,
    severity alert_severity NOT NULL DEFAULT 'medium',
    status alert_status NOT NULL DEFAULT 'active',
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    product_id UUID REFERENCES products(id),
    location_id UUID REFERENCES locations(id),
    current_value DECIMAL(12,3),
    threshold_value DECIMAL(12,3),
    variance_percentage DECIMAL(5,2),
    expiry_date DATE,
    days_until_expiry INTEGER,
    last_movement_date TIMESTAMP,
    days_since_movement INTEGER,
    reference_type VARCHAR(50),
    reference_id UUID,
    reference_data JSONB,
    auto_generated BOOLEAN DEFAULT true,
    requires_action BOOLEAN DEFAULT false,
    escalation_level INTEGER DEFAULT 0,
    escalated_at TIMESTAMP,
    escalated_to UUID REFERENCES users(id),
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMP,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP,
    resolution_notes TEXT,
    dismissed_by UUID REFERENCES users(id),
    dismissed_at TIMESTAMP,
    dismissal_reason TEXT,
    expires_at TIMESTAMP,
    notification_sent BOOLEAN DEFAULT false,
    notification_sent_at TIMESTAMP,
    notification_count INTEGER DEFAULT 0,
    last_notification_at TIMESTAMP,
    tags JSONB,
    custom_fields JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create indexes for performance
CREATE INDEX idx_alerts_alert_code ON alerts(alert_code);
CREATE INDEX idx_alerts_alert_type ON alerts(alert_type);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_product_id ON alerts(product_id);
CREATE INDEX idx_alerts_location_id ON alerts(location_id);
CREATE INDEX idx_alerts_created_at ON alerts(created_at);
CREATE INDEX idx_alerts_expires_at ON alerts(expires_at);
CREATE INDEX idx_alerts_escalation_level ON alerts(escalation_level);
CREATE INDEX idx_alerts_auto_generated ON alerts(auto_generated);
CREATE INDEX idx_alerts_requires_action ON alerts(requires_action);

-- Composite indexes for common queries
CREATE INDEX idx_alerts_active ON alerts(status, severity, created_at DESC) 
    WHERE status = 'active';

CREATE INDEX idx_alerts_product_active ON alerts(product_id, status, alert_type) 
    WHERE status = 'active';

CREATE INDEX idx_alerts_location_active ON alerts(location_id, status, alert_type) 
    WHERE status = 'active';

CREATE INDEX idx_alerts_pending_notification ON alerts(notification_sent, created_at) 
    WHERE notification_sent = false AND status = 'active';

-- Create trigger for updated_at
CREATE TRIGGER update_alerts_updated_at 
    BEFORE UPDATE ON alerts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to generate alert codes
CREATE OR REPLACE FUNCTION generate_alert_code()
RETURNS TRIGGER AS $$
DECLARE
    type_prefix VARCHAR(5);
    sequence_num INTEGER;
    new_code VARCHAR(20);
BEGIN
    -- Set prefix based on alert type
    type_prefix := CASE NEW.alert_type
        WHEN 'low_stock' THEN 'LS'
        WHEN 'out_of_stock' THEN 'OS'
        WHEN 'overstock' THEN 'OV'
        WHEN 'expiry_warning' THEN 'EW'
        WHEN 'expired' THEN 'EX'
        WHEN 'slow_moving' THEN 'SM'
        WHEN 'fast_moving' THEN 'FM'
        WHEN 'negative_stock' THEN 'NS'
        WHEN 'cycle_count_due' THEN 'CC'
        WHEN 'price_change' THEN 'PC'
        WHEN 'cost_variance' THEN 'CV'
        WHEN 'system_error' THEN 'SE'
        ELSE 'AL'
    END;
    
    -- Get next sequence number for today
    SELECT COALESCE(MAX(CAST(SUBSTRING(alert_code FROM LENGTH(type_prefix || TO_CHAR(CURRENT_DATE, 'YYMMDD')) + 1) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM alerts
    WHERE alert_code LIKE type_prefix || TO_CHAR(CURRENT_DATE, 'YYMMDD') || '%';
    
    -- Generate new alert code
    new_code := type_prefix || TO_CHAR(CURRENT_DATE, 'YYMMDD') || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.alert_code := new_code;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for alert code generation
CREATE TRIGGER generate_alert_code_trigger
    BEFORE INSERT ON alerts
    FOR EACH ROW
    WHEN (NEW.alert_code IS NULL)
    EXECUTE FUNCTION generate_alert_code();

-- Function to auto-expire alerts
CREATE OR REPLACE FUNCTION auto_expire_alerts()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-expire alerts that have passed their expiry date
    IF NEW.expires_at IS NOT NULL AND NEW.expires_at <= CURRENT_TIMESTAMP AND NEW.status = 'active' THEN
        NEW.status := 'expired';
        NEW.updated_at := CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-expiring alerts
CREATE TRIGGER auto_expire_alerts_trigger
    BEFORE UPDATE ON alerts
    FOR EACH ROW
    EXECUTE FUNCTION auto_expire_alerts();

-- Function to calculate derived fields
CREATE OR REPLACE FUNCTION calculate_alert_derived_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate days until expiry
    IF NEW.expiry_date IS NOT NULL THEN
        NEW.days_until_expiry := NEW.expiry_date - CURRENT_DATE;
    END IF;
    
    -- Calculate days since last movement
    IF NEW.last_movement_date IS NOT NULL THEN
        NEW.days_since_movement := EXTRACT(DAY FROM CURRENT_TIMESTAMP - NEW.last_movement_date)::INTEGER;
    END IF;
    
    -- Calculate variance percentage
    IF NEW.current_value IS NOT NULL AND NEW.threshold_value IS NOT NULL AND NEW.threshold_value != 0 THEN
        NEW.variance_percentage := ((NEW.current_value - NEW.threshold_value) / NEW.threshold_value) * 100;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for derived field calculation
CREATE TRIGGER calculate_alert_derived_fields_trigger
    BEFORE INSERT OR UPDATE ON alerts
    FOR EACH ROW
    EXECUTE FUNCTION calculate_alert_derived_fields();

-- Function to create stock alerts automatically
CREATE OR REPLACE FUNCTION create_stock_alerts()
RETURNS TRIGGER AS $$
DECLARE
    alert_exists BOOLEAN;
    alert_title VARCHAR(255);
    alert_message TEXT;
    alert_sev alert_severity;
BEGIN
    -- Only process for trackable products at active locations
    IF NOT EXISTS (
        SELECT 1 FROM products p 
        JOIN locations l ON l.id = NEW.location_id
        WHERE p.id = NEW.product_id 
            AND p.is_trackable = true 
            AND p.is_active = true 
            AND l.is_active = true
    ) THEN
        RETURN NEW;
    END IF;
    
    -- Check for out of stock
    IF NEW.quantity <= 0 THEN
        -- Check if alert already exists
        SELECT EXISTS(
            SELECT 1 FROM alerts 
            WHERE product_id = NEW.product_id 
                AND location_id = NEW.location_id 
                AND alert_type = 'out_of_stock' 
                AND status = 'active'
        ) INTO alert_exists;
        
        IF NOT alert_exists THEN
            SELECT p.name INTO alert_title FROM products p WHERE p.id = NEW.product_id;
            alert_message := 'Producto sin stock disponible en ' || (SELECT name FROM locations WHERE id = NEW.location_id);
            
            INSERT INTO alerts (
                alert_type, severity, title, message, product_id, location_id,
                current_value, threshold_value, auto_generated, requires_action
            ) VALUES (
                'out_of_stock', 'high', 'Sin Stock: ' || alert_title, alert_message,
                NEW.product_id, NEW.location_id, NEW.quantity, 0, true, true
            );
        END IF;
    END IF;
    
    -- Check for low stock
    IF NEW.min_stock IS NOT NULL AND NEW.quantity > 0 AND NEW.quantity <= NEW.min_stock THEN
        -- Check if alert already exists
        SELECT EXISTS(
            SELECT 1 FROM alerts 
            WHERE product_id = NEW.product_id 
                AND location_id = NEW.location_id 
                AND alert_type = 'low_stock' 
                AND status = 'active'
        ) INTO alert_exists;
        
        IF NOT alert_exists THEN
            SELECT p.name INTO alert_title FROM products p WHERE p.id = NEW.product_id;
            alert_message := 'Stock bajo el mínimo configurado (' || NEW.min_stock || ' unidades)';
            alert_sev := CASE WHEN NEW.quantity <= (NEW.min_stock * 0.5) THEN 'high' ELSE 'medium' END;
            
            INSERT INTO alerts (
                alert_type, severity, title, message, product_id, location_id,
                current_value, threshold_value, auto_generated, requires_action
            ) VALUES (
                'low_stock', alert_sev, 'Stock Bajo: ' || alert_title, alert_message,
                NEW.product_id, NEW.location_id, NEW.quantity, NEW.min_stock, true, true
            );
        END IF;
    END IF;
    
    -- Check for overstock
    IF NEW.max_stock IS NOT NULL AND NEW.quantity > NEW.max_stock THEN
        -- Check if alert already exists
        SELECT EXISTS(
            SELECT 1 FROM alerts 
            WHERE product_id = NEW.product_id 
                AND location_id = NEW.location_id 
                AND alert_type = 'overstock' 
                AND status = 'active'
        ) INTO alert_exists;
        
        IF NOT alert_exists THEN
            SELECT p.name INTO alert_title FROM products p WHERE p.id = NEW.product_id;
            alert_message := 'Stock excede el máximo recomendado (' || NEW.max_stock || ' unidades)';
            
            INSERT INTO alerts (
                alert_type, severity, title, message, product_id, location_id,
                current_value, threshold_value, auto_generated, requires_action
            ) VALUES (
                'overstock', 'low', 'Sobrestock: ' || alert_title, alert_message,
                NEW.product_id, NEW.location_id, NEW.quantity, NEW.max_stock, true, false
            );
        END IF;
    END IF;
    
    -- Resolve existing alerts if conditions are no longer met
    UPDATE alerts SET 
        status = 'resolved',
        resolved_at = CURRENT_TIMESTAMP,
        resolution_notes = 'Condición de alerta resuelta automáticamente'
    WHERE product_id = NEW.product_id 
        AND location_id = NEW.location_id 
        AND status = 'active'
        AND (
            (alert_type = 'out_of_stock' AND NEW.quantity > 0) OR
            (alert_type = 'low_stock' AND (NEW.min_stock IS NULL OR NEW.quantity > NEW.min_stock)) OR
            (alert_type = 'overstock' AND (NEW.max_stock IS NULL OR NEW.quantity <= NEW.max_stock))
        );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic stock alert creation
CREATE TRIGGER create_stock_alerts_trigger
    AFTER INSERT OR UPDATE ON stock_levels
    FOR EACH ROW
    EXECUTE FUNCTION create_stock_alerts();

-- Add constraints
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_escalation_level 
    CHECK (escalation_level >= 0 AND escalation_level <= 5);

ALTER TABLE alerts ADD CONSTRAINT chk_alerts_notification_count 
    CHECK (notification_count >= 0);

-- Add comments
COMMENT ON TABLE alerts IS 'System alerts and notifications for inventory management';
COMMENT ON COLUMN alerts.alert_code IS 'Unique alert identifier (auto-generated)';
COMMENT ON COLUMN alerts.alert_type IS 'Type of alert condition';
COMMENT ON COLUMN alerts.severity IS 'Alert severity level';
COMMENT ON COLUMN alerts.status IS 'Current status of the alert';
COMMENT ON COLUMN alerts.current_value IS 'Current value that triggered the alert';
COMMENT ON COLUMN alerts.threshold_value IS 'Threshold value that was exceeded';
COMMENT ON COLUMN alerts.variance_percentage IS 'Percentage variance from threshold';
COMMENT ON COLUMN alerts.auto_generated IS 'Whether alert was generated automatically';
COMMENT ON COLUMN alerts.requires_action IS 'Whether alert requires user action';
COMMENT ON COLUMN alerts.escalation_level IS 'Current escalation level (0-5)';
COMMENT ON COLUMN alerts.notification_count IS 'Number of notifications sent';

-- Create view for active alerts summary
CREATE VIEW active_alerts_summary AS
SELECT 
    alert_type,
    severity,
    COUNT(*) as alert_count,
    COUNT(CASE WHEN requires_action THEN 1 END) as action_required_count,
    MIN(created_at) as oldest_alert,
    MAX(created_at) as newest_alert
FROM alerts
WHERE status = 'active'
GROUP BY alert_type, severity
ORDER BY 
    CASE severity 
        WHEN 'critical' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        WHEN 'low' THEN 4 
    END,
    alert_count DESC;

COMMENT ON VIEW active_alerts_summary IS 'Summary of active alerts by type and severity';

-- Migration completed successfully
SELECT 'Migration 007_create_alerts_table.sql completed successfully' as status;