-- Migration: 002_create_products_table.sql
-- Description: Create products table for inventory management
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- Create products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id),
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
    cost_price DECIMAL(12,2) CHECK (cost_price >= 0),
    unit_of_measure VARCHAR(20) NOT NULL DEFAULT 'unidad',
    barcode VARCHAR(50),
    qr_code VARCHAR(255),
    weight DECIMAL(8,3) CHECK (weight >= 0),
    dimensions JSONB, -- {length, width, height, unit}
    tax_rate DECIMAL(5,2) DEFAULT 0.00 CHECK (tax_rate >= 0 AND tax_rate <= 100),
    is_active BOOLEAN DEFAULT true,
    is_trackable BOOLEAN DEFAULT true,
    min_stock_level DECIMAL(10,3) DEFAULT 0,
    max_stock_level DECIMAL(10,3),
    reorder_point DECIMAL(10,3),
    reorder_quantity DECIMAL(10,3),
    lead_time_days INTEGER DEFAULT 0,
    shelf_life_days INTEGER,
    storage_requirements TEXT,
    handling_instructions TEXT,
    image_url VARCHAR(500),
    images JSONB, -- Array of image URLs
    tags JSONB, -- Array of tags for search
    custom_fields JSONB, -- Flexible custom attributes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create indexes for performance
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_products_created_at ON products(created_at);
CREATE INDEX idx_products_unit_price ON products(unit_price);

-- Full-text search index
CREATE INDEX idx_products_search ON products USING gin(to_tsvector('spanish', name || ' ' || COALESCE(description, '')));

-- JSONB indexes for flexible queries
CREATE INDEX idx_products_tags ON products USING gin(tags);
CREATE INDEX idx_products_custom_fields ON products USING gin(custom_fields);

-- Create trigger for updated_at
CREATE TRIGGER update_products_updated_at 
    BEFORE UPDATE ON products 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Add constraints
ALTER TABLE products ADD CONSTRAINT chk_products_min_max_stock 
    CHECK (max_stock_level IS NULL OR min_stock_level <= max_stock_level);

ALTER TABLE products ADD CONSTRAINT chk_products_reorder_point 
    CHECK (reorder_point IS NULL OR reorder_point >= min_stock_level);

-- Add comments
COMMENT ON TABLE products IS 'Master catalog of products for inventory management';
COMMENT ON COLUMN products.sku IS 'Stock Keeping Unit - unique product identifier';
COMMENT ON COLUMN products.unit_price IS 'Selling price per unit';
COMMENT ON COLUMN products.cost_price IS 'Cost price per unit for margin calculation';
COMMENT ON COLUMN products.unit_of_measure IS 'Unit of measurement (kg, lt, unidad, etc.)';
COMMENT ON COLUMN products.dimensions IS 'Product dimensions in JSON format';
COMMENT ON COLUMN products.is_trackable IS 'Whether this product should be tracked in inventory';
COMMENT ON COLUMN products.min_stock_level IS 'Minimum stock level before alert';
COMMENT ON COLUMN products.max_stock_level IS 'Maximum recommended stock level';
COMMENT ON COLUMN products.reorder_point IS 'Stock level that triggers reorder';
COMMENT ON COLUMN products.reorder_quantity IS 'Suggested quantity to reorder';
COMMENT ON COLUMN products.lead_time_days IS 'Days between order and delivery';
COMMENT ON COLUMN products.shelf_life_days IS 'Product shelf life in days';
COMMENT ON COLUMN products.tags IS 'JSON array of tags for categorization and search';
COMMENT ON COLUMN products.custom_fields IS 'JSON object for custom product attributes';

-- Migration completed successfully
SELECT 'Migration 002_create_products_table.sql completed successfully' as status;