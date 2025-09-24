-- Seed: demo-data.sql
-- Description: Insert comprehensive demo data for testing and demonstration
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- Disable triggers temporarily for bulk insert
SELECT toggle_triggers('users', false);
SELECT toggle_triggers('products', false);
SELECT toggle_triggers('stock_levels', false);
SELECT toggle_triggers('inventory_movements', false);

-- ==================== DEMO USERS ====================

INSERT INTO users (id, email, password_hash, first_name, last_name, role, is_active, email_verified, created_by) VALUES
-- Admin users
('11111111-1111-1111-1111-111111111111', 'admin@demo.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Administrador', 'Principal', 'admin', true, true, NULL),
('22222222-2222-2222-2222-222222222222', 'gerente@demo.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'María', 'González', 'manager', true, true, '11111111-1111-1111-1111-111111111111'),

-- Warehouse users
('33333333-3333-3333-3333-333333333333', 'bodega1@demo.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Carlos', 'Rodríguez', 'warehouse', true, true, '11111111-1111-1111-1111-111111111111'),
('44444444-4444-4444-4444-444444444444', 'bodega2@demo.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Ana', 'Martínez', 'warehouse', true, true, '11111111-1111-1111-1111-111111111111'),

-- Sales users
('55555555-5555-5555-5555-555555555555', 'ventas1@demo.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Luis', 'Pérez', 'sales', true, true, '22222222-2222-2222-2222-222222222222'),
('66666666-6666-6666-6666-666666666666', 'ventas2@demo.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Sandra', 'López', 'sales', true, true, '22222222-2222-2222-2222-222222222222'),

-- Viewer users
('77777777-7777-7777-7777-777777777777', 'consulta@demo.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Roberto', 'Silva', 'viewer', true, true, '22222222-2222-2222-2222-222222222222');

-- ==================== DEMO LOCATIONS ====================

-- Update existing locations with managers
UPDATE locations SET manager_id = '33333333-3333-3333-3333-333333333333' WHERE code = 'MAIN-WH';
UPDATE locations SET manager_id = '55555555-5555-5555-5555-555555555555' WHERE code = 'STORE-01';

-- Add more demo locations
INSERT INTO locations (id, code, name, type, description, city, country, manager_id, is_active, storage_capacity, storage_unit, created_by) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'WH-02', 'Bodega Secundaria', 'warehouse', 'Bodega de respaldo y overflow', 'Medellín', 'Colombia', '44444444-4444-4444-4444-444444444444', true, 500.00, 'm3', '11111111-1111-1111-1111-111111111111'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'STORE-02', 'Tienda Norte', 'store', 'Sucursal zona norte', 'Barranquilla', 'Colombia', '55555555-5555-5555-5555-555555555555', true, 150.00, 'm2', '11111111-1111-1111-1111-111111111111'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'OUTLET', 'Tienda Outlet', 'store', 'Tienda de productos en liquidación', 'Cali', 'Colombia', '66666666-6666-6666-6666-666666666666', true, 200.00, 'm2', '11111111-1111-1111-1111-111111111111');

-- ==================== DEMO SUPPLIERS ====================

INSERT INTO suppliers (id, company_name, tax_id, supplier_type, status, primary_contact_name, primary_contact_email, primary_contact_phone, city, country, payment_terms, credit_days, lead_time_days, preferred_supplier, created_by) VALUES
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'TechnoSupply S.A.S.', '900111222-3', 'distributor', 'active', 'Jorge Ramírez', 'jorge@technosupply.com', '+57-1-555-0001', 'Bogotá', 'Colombia', 'Net 30', 30, 5, true, '11111111-1111-1111-1111-111111111111'),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Electrónicos del Valle', '800333444-5', 'wholesaler', 'active', 'Patricia Morales', 'patricia@electrovalle.com', '+57-2-555-0002', 'Cali', 'Colombia', 'Net 15', 15, 3, false, '11111111-1111-1111-1111-111111111111'),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Importaciones Globales', '700555666-7', 'manufacturer', 'active', 'Miguel Torres', 'miguel@impglobales.com', '+57-4-555-0003', 'Medellín', 'Colombia', 'COD', 0, 14, false, '11111111-1111-1111-1111-111111111111');

-- ==================== DEMO PRODUCTS ====================

-- Get category IDs for reference
DO $$
DECLARE
    cat_electronicos UUID;
    cat_computadoras UUID;
    cat_telefonos UUID;
    cat_audio UUID;
    cat_oficina UUID;
BEGIN
    SELECT id INTO cat_electronicos FROM categories WHERE slug = 'electronicos';
    SELECT id INTO cat_computadoras FROM categories WHERE slug = 'computadoras';
    SELECT id INTO cat_telefonos FROM categories WHERE slug = 'telefonos';
    SELECT id INTO cat_audio FROM categories WHERE slug = 'audio';
    SELECT id INTO cat_oficina FROM categories WHERE slug = 'oficina';

    -- Insert demo products
    INSERT INTO products (id, sku, name, description, category_id, unit_price, cost_price, unit_of_measure, barcode, min_stock_level, max_stock_level, reorder_point, reorder_quantity, is_active, is_trackable, created_by) VALUES
    
    -- Computadoras
    ('10000000-0000-0000-0000-000000000001', 'LAPTOP-DEL-001', 'Laptop Dell Inspiron 15', 'Laptop Dell Inspiron 15 3000, Intel i5, 8GB RAM, 256GB SSD', cat_computadoras, 2500000.00, 2000000.00, 'unidad', '7891234567001', 5, 50, 10, 20, true, true, '11111111-1111-1111-1111-111111111111'),
    ('10000000-0000-0000-0000-000000000002', 'LAPTOP-HP-001', 'Laptop HP Pavilion', 'HP Pavilion 14, AMD Ryzen 5, 8GB RAM, 512GB SSD', cat_computadoras, 2200000.00, 1800000.00, 'unidad', '7891234567002', 3, 30, 8, 15, true, true, '11111111-1111-1111-1111-111111111111'),
    ('10000000-0000-0000-0000-000000000003', 'DESKTOP-LEN-001', 'Desktop Lenovo ThinkCentre', 'Lenovo ThinkCentre M720s, Intel i7, 16GB RAM, 1TB HDD', cat_computadoras, 3200000.00, 2600000.00, 'unidad', '7891234567003', 2, 20, 5, 10, true, true, '11111111-1111-1111-1111-111111111111'),
    
    -- Teléfonos
    ('10000000-0000-0000-0000-000000000004', 'PHONE-SAM-001', 'Samsung Galaxy A54', 'Samsung Galaxy A54 5G, 128GB, Cámara 50MP', cat_telefonos, 1200000.00, 950000.00, 'unidad', '7891234567004', 10, 100, 20, 40, true, true, '11111111-1111-1111-1111-111111111111'),
    ('10000000-0000-0000-0000-000000000005', 'PHONE-IPH-001', 'iPhone 13', 'Apple iPhone 13, 128GB, Azul', cat_telefonos, 3500000.00, 2800000.00, 'unidad', '7891234567005', 5, 50, 10, 20, true, true, '11111111-1111-1111-1111-111111111111'),
    ('10000000-0000-0000-0000-000000000006', 'PHONE-XIA-001', 'Xiaomi Redmi Note 12', 'Xiaomi Redmi Note 12 Pro, 256GB, Cámara 108MP', cat_telefonos, 800000.00, 650000.00, 'unidad', '7891234567006', 15, 80, 25, 50, true, true, '11111111-1111-1111-1111-111111111111'),
    
    -- Audio
    ('10000000-0000-0000-0000-000000000007', 'HEADPH-SON-001', 'Audífonos Sony WH-1000XM4', 'Sony WH-1000XM4, Cancelación de ruido, Bluetooth', cat_audio, 850000.00, 680000.00, 'unidad', '7891234567007', 8, 60, 15, 30, true, true, '11111111-1111-1111-1111-111111111111'),
    ('10000000-0000-0000-0000-000000000008', 'SPEAKER-JBL-001', 'Parlante JBL Charge 5', 'JBL Charge 5, Bluetooth, Resistente al agua IP67', cat_audio, 450000.00, 360000.00, 'unidad', '7891234567008', 12, 80, 20, 40, true, true, '11111111-1111-1111-1111-111111111111'),
    ('10000000-0000-0000-0000-000000000009', 'EARBUDS-APP-001', 'AirPods Pro 2da Gen', 'Apple AirPods Pro 2da Generación, Cancelación activa', cat_audio, 950000.00, 760000.00, 'unidad', '7891234567009', 6, 40, 12, 24, true, true, '11111111-1111-1111-1111-111111111111'),
    
    -- Oficina
    ('10000000-0000-0000-0000-000000000010', 'MOUSE-LOG-001', 'Mouse Logitech MX Master 3', 'Logitech MX Master 3, Inalámbrico, Ergonómico', cat_oficina, 320000.00, 250000.00, 'unidad', '7891234567010', 20, 150, 35, 70, true, true, '11111111-1111-1111-1111-111111111111'),
    ('10000000-0000-0000-0000-000000000011', 'KEYBOARD-LOG-001', 'Teclado Logitech MX Keys', 'Logitech MX Keys, Inalámbrico, Retroiluminado', cat_oficina, 450000.00, 360000.00, 'unidad', '7891234567011', 15, 100, 25, 50, true, true, '11111111-1111-1111-1111-111111111111'),
    ('10000000-0000-0000-0000-000000000012', 'MONITOR-LG-001', 'Monitor LG 24 pulgadas', 'LG 24MK430H, Full HD, IPS, 75Hz', cat_oficina, 650000.00, 520000.00, 'unidad', '7891234567012', 8, 60, 15, 30, true, true, '11111111-1111-1111-1111-111111111111');

END $$;

-- ==================== DEMO STOCK LEVELS ====================

-- Insert initial stock levels for all products in main warehouse
INSERT INTO stock_levels (product_id, location_id, quantity, min_stock, max_stock, reorder_point, reorder_quantity, average_cost, last_cost, created_by) 
SELECT 
    p.id,
    (SELECT id FROM locations WHERE code = 'MAIN-WH'),
    CASE 
        WHEN p.sku LIKE '%LAPTOP%' THEN 25
        WHEN p.sku LIKE '%DESKTOP%' THEN 15
        WHEN p.sku LIKE '%PHONE%' THEN 45
        WHEN p.sku LIKE '%HEADPH%' THEN 30
        WHEN p.sku LIKE '%SPEAKER%' THEN 40
        WHEN p.sku LIKE '%EARBUDS%' THEN 20
        WHEN p.sku LIKE '%MOUSE%' THEN 75
        WHEN p.sku LIKE '%KEYBOARD%' THEN 50
        WHEN p.sku LIKE '%MONITOR%' THEN 25
        ELSE 10
    END as quantity,
    p.min_stock_level,
    p.max_stock_level,
    p.reorder_point,
    p.reorder_quantity,
    p.cost_price,
    p.cost_price,
    '11111111-1111-1111-1111-111111111111'
FROM products p
WHERE p.sku LIKE '%-001';

-- Add some stock in secondary locations
INSERT INTO stock_levels (product_id, location_id, quantity, min_stock, max_stock, average_cost, last_cost, created_by)
SELECT 
    p.id,
    l.id,
    CASE 
        WHEN l.code = 'STORE-01' THEN FLOOR(RANDOM() * 15 + 5)::INTEGER
        WHEN l.code = 'WH-02' THEN FLOOR(RANDOM() * 20 + 10)::INTEGER
        WHEN l.code = 'STORE-02' THEN FLOOR(RANDOM() * 12 + 3)::INTEGER
        ELSE 5
    END as quantity,
    CASE WHEN l.type = 'store' THEN 3 ELSE 5 END,
    CASE WHEN l.type = 'store' THEN 20 ELSE 30 END,
    p.cost_price,
    p.cost_price,
    '11111111-1111-1111-1111-111111111111'
FROM products p
CROSS JOIN locations l
WHERE p.sku LIKE '%-001' 
    AND l.code IN ('STORE-01', 'WH-02', 'STORE-02')
    AND RANDOM() > 0.3; -- Only add stock to 70% of product-location combinations

-- ==================== DEMO INVENTORY MOVEMENTS ====================

-- Generate some historical movements (last 30 days)
DO $$
DECLARE
    product_record RECORD;
    location_record RECORD;
    movement_date DATE;
    i INTEGER;
BEGIN
    -- Generate movements for the last 30 days
    FOR i IN 1..30 LOOP
        movement_date := CURRENT_DATE - (i || ' days')::INTERVAL;
        
        -- Generate some random incoming movements
        FOR product_record IN 
            SELECT id, cost_price FROM products WHERE sku LIKE '%-001' ORDER BY RANDOM() LIMIT 3
        LOOP
            FOR location_record IN 
                SELECT id FROM locations WHERE type = 'warehouse' ORDER BY RANDOM() LIMIT 1
            LOOP
                INSERT INTO inventory_movements (
                    product_id, location_id, movement_type, quantity, unit_cost,
                    reference_type, reference_number, processed_at, processed_by,
                    supplier_id, notes
                ) VALUES (
                    product_record.id,
                    location_record.id,
                    'in',
                    FLOOR(RANDOM() * 20 + 5)::INTEGER,
                    product_record.cost_price,
                    'purchase_order',
                    'PO-' || TO_CHAR(movement_date, 'YYYYMMDD') || '-' || LPAD((RANDOM() * 999)::INTEGER::TEXT, 3, '0'),
                    movement_date + (RANDOM() * INTERVAL '12 hours'),
                    '33333333-3333-3333-3333-333333333333',
                    (SELECT id FROM suppliers ORDER BY RANDOM() LIMIT 1),
                    'Recepción de mercancía'
                );
            END LOOP;
        END LOOP;
        
        -- Generate some outgoing movements (sales)
        FOR product_record IN 
            SELECT id FROM products WHERE sku LIKE '%-001' ORDER BY RANDOM() LIMIT 2
        LOOP
            FOR location_record IN 
                SELECT id FROM locations WHERE type IN ('store', 'warehouse') ORDER BY RANDOM() LIMIT 1
            LOOP
                INSERT INTO inventory_movements (
                    product_id, location_id, movement_type, quantity,
                    reference_type, reference_number, processed_at, processed_by,
                    notes
                ) VALUES (
                    product_record.id,
                    location_record.id,
                    'out',
                    FLOOR(RANDOM() * 8 + 1)::INTEGER,
                    'sales_order',
                    'SO-' || TO_CHAR(movement_date, 'YYYYMMDD') || '-' || LPAD((RANDOM() * 999)::INTEGER::TEXT, 3, '0'),
                    movement_date + (RANDOM() * INTERVAL '12 hours'),
                    CASE 
                        WHEN RANDOM() > 0.5 THEN '55555555-5555-5555-5555-555555555555'
                        ELSE '66666666-6666-6666-6666-666666666666'
                    END,
                    'Venta a cliente'
                );
            END LOOP;
        END LOOP;
        
        -- Occasional transfers
        IF RANDOM() > 0.7 THEN
            FOR product_record IN 
                SELECT id FROM products WHERE sku LIKE '%-001' ORDER BY RANDOM() LIMIT 1
            LOOP
                INSERT INTO inventory_movements (
                    product_id, location_id, destination_location_id, movement_type, quantity,
                    reference_type, reference_number, processed_at, processed_by,
                    notes
                ) VALUES (
                    product_record.id,
                    (SELECT id FROM locations WHERE code = 'MAIN-WH'),
                    (SELECT id FROM locations WHERE type = 'store' ORDER BY RANDOM() LIMIT 1),
                    'transfer',
                    FLOOR(RANDOM() * 5 + 1)::INTEGER,
                    'transfer_order',
                    'TR-' || TO_CHAR(movement_date, 'YYYYMMDD') || '-' || LPAD((RANDOM() * 999)::INTEGER::TEXT, 3, '0'),
                    movement_date + (RANDOM() * INTERVAL '12 hours'),
                    '33333333-3333-3333-3333-333333333333',
                    'Transferencia entre ubicaciones'
                );
            END LOOP;
        END IF;
    END LOOP;
END $$;

-- ==================== DEMO ALERTS ====================

-- Create some sample alerts (these will be auto-generated by triggers, but we'll add a few manually for demo)
INSERT INTO alerts (alert_type, severity, title, message, product_id, location_id, current_value, threshold_value, auto_generated, requires_action, created_by) 
SELECT 
    'low_stock',
    'medium',
    'Stock Bajo: ' || p.name,
    'El producto tiene stock por debajo del mínimo configurado',
    p.id,
    sl.location_id,
    sl.quantity,
    sl.min_stock,
    true,
    true,
    '11111111-1111-1111-1111-111111111111'
FROM products p
JOIN stock_levels sl ON p.id = sl.product_id
WHERE sl.quantity <= sl.min_stock
    AND sl.min_stock IS NOT NULL
LIMIT 3;

-- Re-enable triggers
SELECT toggle_triggers('users', true);
SELECT toggle_triggers('products', true);
SELECT toggle_triggers('stock_levels', true);
SELECT toggle_triggers('inventory_movements', true);

-- Update statistics after bulk insert
ANALYZE users;
ANALYZE products;
ANALYZE categories;
ANALYZE locations;
ANALYZE stock_levels;
ANALYZE inventory_movements;
ANALYZE alerts;
ANALYZE suppliers;

-- Demo data summary
SELECT 'Demo data inserted successfully' as status;
SELECT 
    'Users: ' || (SELECT COUNT(*) FROM users) ||
    ', Products: ' || (SELECT COUNT(*) FROM products) ||
    ', Locations: ' || (SELECT COUNT(*) FROM locations) ||
    ', Suppliers: ' || (SELECT COUNT(*) FROM suppliers) ||
    ', Stock Records: ' || (SELECT COUNT(*) FROM stock_levels) ||
    ', Movements: ' || (SELECT COUNT(*) FROM inventory_movements) ||
    ', Alerts: ' || (SELECT COUNT(*) FROM alerts)
    as summary;