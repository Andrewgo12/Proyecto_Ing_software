-- Migration: 004_create_locations_table.sql
-- Description: Create locations table for multi-warehouse inventory
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- Create location types enum
CREATE TYPE location_type AS ENUM ('warehouse', 'store', 'transit', 'supplier', 'customer', 'virtual');

-- Create locations table
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    type location_type NOT NULL DEFAULT 'warehouse',
    description TEXT,
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Colombia',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone VARCHAR(20),
    email VARCHAR(255),
    manager_id UUID REFERENCES users(id),
    parent_location_id UUID REFERENCES locations(id),
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    allows_negative_stock BOOLEAN DEFAULT false,
    storage_capacity DECIMAL(12,2),
    storage_unit VARCHAR(20) DEFAULT 'm3',
    operating_hours JSONB, -- {monday: {open: "08:00", close: "18:00"}, ...}
    timezone VARCHAR(50) DEFAULT 'America/Bogota',
    cost_center VARCHAR(50),
    gl_account VARCHAR(50),
    custom_fields JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create indexes for performance
CREATE INDEX idx_locations_code ON locations(code);
CREATE INDEX idx_locations_name ON locations(name);
CREATE INDEX idx_locations_type ON locations(type);
CREATE INDEX idx_locations_is_active ON locations(is_active);
CREATE INDEX idx_locations_is_default ON locations(is_default);
CREATE INDEX idx_locations_manager_id ON locations(manager_id);
CREATE INDEX idx_locations_parent_location_id ON locations(parent_location_id);
CREATE INDEX idx_locations_city ON locations(city);
CREATE INDEX idx_locations_country ON locations(country);

-- Geospatial index for location-based queries
CREATE INDEX idx_locations_coordinates ON locations USING gist(point(longitude, latitude));

-- Create trigger for updated_at
CREATE TRIGGER update_locations_updated_at 
    BEFORE UPDATE ON locations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to ensure only one default location
CREATE OR REPLACE FUNCTION ensure_single_default_location()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this location as default, unset all others
    IF NEW.is_default = true THEN
        UPDATE locations 
        SET is_default = false 
        WHERE id != NEW.id AND is_default = true;
    END IF;
    
    -- Ensure at least one active location exists
    IF NEW.is_active = false THEN
        IF NOT EXISTS (SELECT 1 FROM locations WHERE is_active = true AND id != NEW.id) THEN
            RAISE EXCEPTION 'At least one location must remain active';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for default location management
CREATE TRIGGER ensure_single_default_location_trigger
    BEFORE INSERT OR UPDATE ON locations
    FOR EACH ROW
    WHEN (NEW.is_default = true)
    EXECUTE FUNCTION ensure_single_default_location();

-- Function to validate coordinates
CREATE OR REPLACE FUNCTION validate_coordinates()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate latitude range
    IF NEW.latitude IS NOT NULL AND (NEW.latitude < -90 OR NEW.latitude > 90) THEN
        RAISE EXCEPTION 'Latitude must be between -90 and 90 degrees';
    END IF;
    
    -- Validate longitude range
    IF NEW.longitude IS NOT NULL AND (NEW.longitude < -180 OR NEW.longitude > 180) THEN
        RAISE EXCEPTION 'Longitude must be between -180 and 180 degrees';
    END IF;
    
    -- Both coordinates must be provided together
    IF (NEW.latitude IS NULL) != (NEW.longitude IS NULL) THEN
        RAISE EXCEPTION 'Both latitude and longitude must be provided together';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for coordinate validation
CREATE TRIGGER validate_coordinates_trigger
    BEFORE INSERT OR UPDATE ON locations
    FOR EACH ROW
    EXECUTE FUNCTION validate_coordinates();

-- Add constraints
ALTER TABLE locations ADD CONSTRAINT chk_locations_storage_capacity 
    CHECK (storage_capacity IS NULL OR storage_capacity > 0);

ALTER TABLE locations ADD CONSTRAINT chk_locations_email 
    CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Prevent self-reference in parent location
ALTER TABLE locations ADD CONSTRAINT chk_locations_no_self_reference 
    CHECK (id != parent_location_id);

-- Add comments
COMMENT ON TABLE locations IS 'Physical and virtual locations for inventory management';
COMMENT ON COLUMN locations.code IS 'Unique location code for identification';
COMMENT ON COLUMN locations.type IS 'Type of location: warehouse, store, transit, etc.';
COMMENT ON COLUMN locations.manager_id IS 'User responsible for this location';
COMMENT ON COLUMN locations.parent_location_id IS 'Parent location for hierarchical organization';
COMMENT ON COLUMN locations.is_default IS 'Whether this is the default location for new items';
COMMENT ON COLUMN locations.allows_negative_stock IS 'Whether negative stock is allowed at this location';
COMMENT ON COLUMN locations.storage_capacity IS 'Maximum storage capacity';
COMMENT ON COLUMN locations.operating_hours IS 'JSON object with operating hours per day';
COMMENT ON COLUMN locations.cost_center IS 'Cost center for accounting purposes';
COMMENT ON COLUMN locations.gl_account IS 'General ledger account code';

-- Insert default locations
INSERT INTO locations (code, name, type, description, city, country, is_default, is_active) VALUES
('MAIN-WH', 'Bodega Principal', 'warehouse', 'Bodega principal de almacenamiento', 'Bogotá', 'Colombia', true, true),
('STORE-01', 'Tienda Centro', 'store', 'Tienda del centro de la ciudad', 'Bogotá', 'Colombia', false, true),
('TRANSIT', 'En Tránsito', 'transit', 'Productos en tránsito entre ubicaciones', null, 'Colombia', false, true);

-- Insert sample operating hours for main warehouse
UPDATE locations 
SET operating_hours = '{
    "monday": {"open": "08:00", "close": "18:00"},
    "tuesday": {"open": "08:00", "close": "18:00"},
    "wednesday": {"open": "08:00", "close": "18:00"},
    "thursday": {"open": "08:00", "close": "18:00"},
    "friday": {"open": "08:00", "close": "18:00"},
    "saturday": {"open": "08:00", "close": "14:00"},
    "sunday": {"open": null, "close": null}
}'::jsonb
WHERE code = 'MAIN-WH';

-- Migration completed successfully
SELECT 'Migration 004_create_locations_table.sql completed successfully' as status;