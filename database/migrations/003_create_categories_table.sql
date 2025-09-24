-- Migration: 003_create_categories_table.sql
-- Description: Create categories table for product organization
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- Create categories table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    parent_id UUID REFERENCES categories(id),
    level INTEGER NOT NULL DEFAULT 0,
    path VARCHAR(500), -- Materialized path for hierarchy
    sort_order INTEGER DEFAULT 0,
    icon VARCHAR(50), -- Icon class or name
    color VARCHAR(7), -- Hex color code
    is_active BOOLEAN DEFAULT true,
    meta_title VARCHAR(255),
    meta_description TEXT,
    custom_fields JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create indexes for performance
CREATE INDEX idx_categories_name ON categories(name);
CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_parent_id ON categories(parent_id);
CREATE INDEX idx_categories_level ON categories(level);
CREATE INDEX idx_categories_path ON categories(path);
CREATE INDEX idx_categories_is_active ON categories(is_active);
CREATE INDEX idx_categories_sort_order ON categories(sort_order);

-- Create trigger for updated_at
CREATE TRIGGER update_categories_updated_at 
    BEFORE UPDATE ON categories 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update category path and level
CREATE OR REPLACE FUNCTION update_category_hierarchy()
RETURNS TRIGGER AS $$
DECLARE
    parent_path VARCHAR(500);
    parent_level INTEGER;
BEGIN
    -- If this is a root category
    IF NEW.parent_id IS NULL THEN
        NEW.level = 0;
        NEW.path = NEW.id::text;
    ELSE
        -- Get parent's path and level
        SELECT path, level INTO parent_path, parent_level
        FROM categories 
        WHERE id = NEW.parent_id;
        
        -- Set new level and path
        NEW.level = parent_level + 1;
        NEW.path = parent_path || '/' || NEW.id::text;
        
        -- Prevent circular references
        IF NEW.path LIKE '%' || NEW.id::text || '/%' || NEW.id::text || '%' THEN
            RAISE EXCEPTION 'Circular reference detected in category hierarchy';
        END IF;
        
        -- Limit hierarchy depth
        IF NEW.level > 5 THEN
            RAISE EXCEPTION 'Category hierarchy cannot exceed 5 levels';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for hierarchy management
CREATE TRIGGER update_category_hierarchy_trigger
    BEFORE INSERT OR UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_category_hierarchy();

-- Function to update child categories when parent changes
CREATE OR REPLACE FUNCTION update_child_categories()
RETURNS TRIGGER AS $$
BEGIN
    -- Update all child categories when parent path changes
    IF OLD.path IS DISTINCT FROM NEW.path THEN
        UPDATE categories 
        SET path = REPLACE(path, OLD.path, NEW.path),
            level = level + (NEW.level - OLD.level)
        WHERE path LIKE OLD.path || '/%';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating child categories
CREATE TRIGGER update_child_categories_trigger
    AFTER UPDATE ON categories
    FOR EACH ROW
    WHEN (OLD.path IS DISTINCT FROM NEW.path)
    EXECUTE FUNCTION update_child_categories();

-- Add constraints
ALTER TABLE categories ADD CONSTRAINT chk_categories_level 
    CHECK (level >= 0 AND level <= 5);

ALTER TABLE categories ADD CONSTRAINT chk_categories_color 
    CHECK (color IS NULL OR color ~ '^#[0-9A-Fa-f]{6}$');

-- Prevent self-reference
ALTER TABLE categories ADD CONSTRAINT chk_categories_no_self_reference 
    CHECK (id != parent_id);

-- Add comments
COMMENT ON TABLE categories IS 'Hierarchical product categories';
COMMENT ON COLUMN categories.slug IS 'URL-friendly category identifier';
COMMENT ON COLUMN categories.parent_id IS 'Parent category for hierarchy';
COMMENT ON COLUMN categories.level IS 'Hierarchy level (0 = root)';
COMMENT ON COLUMN categories.path IS 'Materialized path for efficient queries';
COMMENT ON COLUMN categories.sort_order IS 'Display order within same level';
COMMENT ON COLUMN categories.icon IS 'Icon identifier for UI display';
COMMENT ON COLUMN categories.color IS 'Hex color code for visual identification';

-- Insert default categories
INSERT INTO categories (name, slug, description, icon, color) VALUES
('Electrónicos', 'electronicos', 'Productos electrónicos y tecnológicos', 'fas fa-laptop', '#3498db'),
('Oficina', 'oficina', 'Suministros y equipos de oficina', 'fas fa-briefcase', '#2ecc71'),
('Hogar', 'hogar', 'Productos para el hogar', 'fas fa-home', '#e74c3c'),
('Deportes', 'deportes', 'Artículos deportivos y recreativos', 'fas fa-futbol', '#f39c12'),
('Salud', 'salud', 'Productos de salud y cuidado personal', 'fas fa-heartbeat', '#9b59b6');

-- Insert subcategories for Electrónicos
INSERT INTO categories (name, slug, description, parent_id, icon, color) 
SELECT 
    subcategory.name,
    subcategory.slug,
    subcategory.description,
    c.id,
    subcategory.icon,
    subcategory.color
FROM categories c,
(VALUES 
    ('Computadoras', 'computadoras', 'Laptops, desktops y accesorios', 'fas fa-desktop', '#34495e'),
    ('Teléfonos', 'telefonos', 'Smartphones y accesorios', 'fas fa-mobile-alt', '#1abc9c'),
    ('Audio', 'audio', 'Audífonos, parlantes y equipos de sonido', 'fas fa-headphones', '#e67e22')
) AS subcategory(name, slug, description, icon, color)
WHERE c.slug = 'electronicos';

-- Migration completed successfully
SELECT 'Migration 003_create_categories_table.sql completed successfully' as status;