-- Seed: test-data.sql
-- Description: Insert minimal test data for automated testing
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- ==================== TEST USERS ====================

INSERT INTO users (id, email, password_hash, first_name, last_name, role, is_active, email_verified) VALUES
-- Test admin
('test-admin-0000-0000-000000000001', 'test.admin@test.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Test', 'Admin', 'admin', true, true),
-- Test manager
('test-manager-0000-0000-000000000002', 'test.manager@test.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Test', 'Manager', 'manager', true, true),
-- Test warehouse user
('test-warehouse-0000-0000-000000000003', 'test.warehouse@test.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Test', 'Warehouse', 'warehouse', true, true),
-- Test sales user
('test-sales-0000-0000-0000-000000000004', 'test.sales@test.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Test', 'Sales', 'sales', true, true),
-- Test viewer
('test-viewer-0000-0000-0000-000000000005', 'test.viewer@test.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Test', 'Viewer', 'viewer', true, true),
-- Inactive test user
('test-inactive-0000-0000-000000000006', 'test.inactive@test.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uO8G', 'Test', 'Inactive', 'viewer', false, false);

-- ==================== TEST CATEGORIES ====================

INSERT INTO categories (id, name, slug, description, parent_id, level, path, is_active) VALUES
-- Root test category
('test-cat-root-0000-0000-000000000001', 'Test Electronics', 'test-electronics', 'Test category for electronics', NULL, 0, 'test-cat-root-0000-0000-000000000001', true),
-- Child test category
('test-cat-child-0000-0000-000000000002', 'Test Computers', 'test-computers', 'Test subcategory for computers', 'test-cat-root-0000-0000-000000000001', 1, 'test-cat-root-0000-0000-000000000001/test-cat-child-0000-0000-000000000002', true),
-- Inactive test category
('test-cat-inactive-0000-000000000003', 'Test Inactive', 'test-inactive', 'Inactive test category', NULL, 0, 'test-cat-inactive-0000-000000000003', false);

-- ==================== TEST LOCATIONS ====================

INSERT INTO locations (id, code, name, type, description, city, country, is_active, is_default, allows_negative_stock, manager_id) VALUES
-- Main test warehouse
('test-location-main-0000-000000000001', 'TEST-MAIN', 'Test Main Warehouse', 'warehouse', 'Main test warehouse', 'Test City', 'Colombia', true, true, false, 'test-warehouse-0000-0000-000000000003'),
-- Secondary test location
('test-location-store-0000-000000000002', 'TEST-STORE', 'Test Store', 'store', 'Test retail store', 'Test City', 'Colombia', true, false, false, 'test-sales-0000-0000-0000-000000000004'),
-- Test location allowing negative stock
('test-location-neg-0000-0000-000000000003', 'TEST-NEG', 'Test Negative Stock', 'warehouse', 'Test location allowing negative stock', 'Test City', 'Colombia', true, false, true, 'test-warehouse-0000-0000-000000000003'),
-- Inactive test location
('test-location-inactive-0000-000000000004', 'TEST-INACTIVE', 'Test Inactive Location', 'warehouse', 'Inactive test location', 'Test City', 'Colombia', false, false, false, NULL);

-- ==================== TEST SUPPLIERS ====================

INSERT INTO suppliers (id, supplier_code, company_name, tax_id, supplier_type, status, primary_contact_name, primary_contact_email, city, country, payment_terms, credit_days, lead_time_days, preferred_supplier) VALUES
-- Active test supplier
('test-supplier-active-0000-000000000001', 'TEST001', 'Test Supplier Active', 'TEST-123456-1', 'distributor', 'active', 'Test Contact', 'contact@testsupplier.com', 'Test City', 'Colombia', 'Net 30', 30, 7, true),
-- Inactive test supplier
('test-supplier-inactive-000000000002', 'TEST002', 'Test Supplier Inactive', 'TEST-789012-2', 'wholesaler', 'inactive', 'Test Contact 2', 'contact2@testsupplier.com', 'Test City', 'Colombia', 'Net 15', 15, 5, false);

-- ==================== TEST PRODUCTS ====================

INSERT INTO products (id, sku, name, description, category_id, unit_price, cost_price, unit_of_measure, barcode, min_stock_level, max_stock_level, reorder_point, reorder_quantity, is_active, is_trackable) VALUES
-- Active trackable product
('test-product-active-0000-000000000001', 'TEST-PROD-001', 'Test Product Active', 'Active test product for inventory tracking', 'test-cat-child-0000-0000-000000000002', 100.00, 80.00, 'unidad', 'TEST001', 10, 100, 15, 50, true, true),
-- Active non-trackable product
('test-product-nontrack-000000000002', 'TEST-PROD-002', 'Test Product Non-Trackable', 'Non-trackable test product', 'test-cat-child-0000-0000-000000000002', 50.00, 40.00, 'unidad', 'TEST002', NULL, NULL, NULL, NULL, true, false),
-- Inactive product
('test-product-inactive-000000000003', 'TEST-PROD-003', 'Test Product Inactive', 'Inactive test product', 'test-cat-child-0000-0000-000000000002', 75.00, 60.00, 'unidad', 'TEST003', 5, 50, 10, 25, false, true),
-- Product with no stock limits
('test-product-nolimits-00000000004', 'TEST-PROD-004', 'Test Product No Limits', 'Test product without stock limits', 'test-cat-child-0000-0000-000000000002', 200.00, 160.00, 'unidad', 'TEST004', NULL, NULL, NULL, NULL, true, true),
-- Product for negative stock testing
('test-product-negative-000000000005', 'TEST-PROD-005', 'Test Product Negative', 'Test product for negative stock scenarios', 'test-cat-child-0000-0000-000000000002', 150.00, 120.00, 'unidad', 'TEST005', 5, 25, 8, 20, true, true);

-- ==================== TEST STOCK LEVELS ====================

INSERT INTO stock_levels (product_id, location_id, quantity, reserved_quantity, min_stock, max_stock, reorder_point, reorder_quantity, average_cost, last_cost) VALUES
-- Normal stock level
('test-product-active-0000-000000000001', 'test-location-main-0000-000000000001', 50.0, 5.0, 10, 100, 15, 50, 80.00, 80.00),
-- Low stock level (below minimum)
('test-product-active-0000-000000000001', 'test-location-store-0000-000000000002', 8.0, 0.0, 10, 50, 15, 30, 80.00, 80.00),
-- Zero stock level
('test-product-nolimits-00000000004', 'test-location-main-0000-000000000001', 0.0, 0.0, NULL, NULL, NULL, NULL, 160.00, 160.00),
-- Negative stock level (only in location that allows it)
('test-product-negative-000000000005', 'test-location-neg-0000-0000-000000000003', -5.0, 0.0, 5, 25, 8, 20, 120.00, 120.00),
-- Overstock level
('test-product-nolimits-00000000004', 'test-location-store-0000-000000000002', 150.0, 10.0, 20, 100, 30, 50, 160.00, 160.00);

-- ==================== TEST INVENTORY MOVEMENTS ====================

INSERT INTO inventory_movements (product_id, location_id, movement_type, movement_status, quantity, unit_cost, reference_type, reference_number, processed_by, supplier_id, notes) VALUES
-- Completed incoming movement
('test-product-active-0000-000000000001', 'test-location-main-0000-000000000001', 'in', 'completed', 100.0, 80.00, 'purchase_order', 'TEST-PO-001', 'test-warehouse-0000-0000-000000000003', 'test-supplier-active-0000-000000000001', 'Test incoming stock'),
-- Completed outgoing movement
('test-product-active-0000-000000000001', 'test-location-main-0000-000000000001', 'out', 'completed', 25.0, NULL, 'sales_order', 'TEST-SO-001', 'test-sales-0000-0000-0000-000000000004', NULL, 'Test outgoing stock'),
-- Pending movement
('test-product-active-0000-000000000001', 'test-location-main-0000-000000000001', 'in', 'pending', 50.0, 80.00, 'purchase_order', 'TEST-PO-002', 'test-warehouse-0000-0000-000000000003', 'test-supplier-active-0000-000000000001', 'Test pending movement'),
-- Transfer movement
('test-product-active-0000-000000000001', 'test-location-main-0000-000000000001', 'transfer', 'completed', 20.0, 80.00, 'transfer_order', 'TEST-TR-001', 'test-warehouse-0000-0000-000000000003', NULL, 'Test transfer'),
-- Adjustment movement
('test-product-active-0000-000000000001', 'test-location-store-0000-000000000002', 'adjustment', 'completed', -2.0, NULL, 'cycle_count', 'TEST-ADJ-001', 'test-warehouse-0000-0000-000000000003', NULL, 'Test adjustment');

-- Update transfer movement with destination
UPDATE inventory_movements 
SET destination_location_id = 'test-location-store-0000-000000000002'
WHERE reference_number = 'TEST-TR-001';

-- ==================== TEST ALERTS ====================

INSERT INTO alerts (alert_type, severity, status, title, message, product_id, location_id, current_value, threshold_value, auto_generated, requires_action) VALUES
-- Active low stock alert
('low_stock', 'medium', 'active', 'Test Low Stock Alert', 'Test product has low stock', 'test-product-active-0000-000000000001', 'test-location-store-0000-000000000002', 8.0, 10.0, true, true),
-- Resolved alert
('out_of_stock', 'high', 'resolved', 'Test Out of Stock Alert', 'Test product was out of stock', 'test-product-nolimits-00000000004', 'test-location-main-0000-000000000001', 0.0, 0.0, true, false),
-- Dismissed alert
('overstock', 'low', 'dismissed', 'Test Overstock Alert', 'Test product has excess stock', 'test-product-nolimits-00000000004', 'test-location-store-0000-000000000002', 150.0, 100.0, true, false);

-- ==================== TEST NOTIFICATIONS ====================

INSERT INTO notifications (notification_type, title, message, recipient_user_id, recipient_role, is_read, is_sent) VALUES
-- Unread notification for specific user
('inventory_alert', 'Test Notification User', 'Test notification for specific user', 'test-manager-0000-0000-000000000002', NULL, false, true),
-- Read notification for role
('system_update', 'Test Notification Role', 'Test notification for role', NULL, 'admin', true, true),
-- Unsent notification
('low_stock_alert', 'Test Unsent Notification', 'Test notification not yet sent', 'test-warehouse-0000-0000-000000000003', NULL, false, false);

-- ==================== TEST AUDIT LOG ====================

INSERT INTO audit_log (table_name, record_id, operation, old_values, new_values, changed_fields, user_id) VALUES
-- Product update audit
('products', 'test-product-active-0000-000000000001', 'UPDATE', 
 '{"name": "Test Product Active Old"}', 
 '{"name": "Test Product Active"}', 
 ARRAY['name'], 
 'test-admin-0000-0000-000000000001'),
-- Stock level change audit
('stock_levels', 'test-product-active-0000-000000000001', 'UPDATE',
 '{"quantity": 45.0}',
 '{"quantity": 50.0}',
 ARRAY['quantity'],
 'test-warehouse-0000-0000-000000000003');

-- ==================== VERIFICATION QUERIES ====================

-- Verify test data counts
DO $$
DECLARE
    user_count INTEGER;
    product_count INTEGER;
    location_count INTEGER;
    stock_count INTEGER;
    movement_count INTEGER;
    alert_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users WHERE email LIKE 'test.%@test.com';
    SELECT COUNT(*) INTO product_count FROM products WHERE sku LIKE 'TEST-PROD-%';
    SELECT COUNT(*) INTO location_count FROM locations WHERE code LIKE 'TEST-%';
    SELECT COUNT(*) INTO stock_count FROM stock_levels sl 
        JOIN products p ON sl.product_id = p.id 
        WHERE p.sku LIKE 'TEST-PROD-%';
    SELECT COUNT(*) INTO movement_count FROM inventory_movements im
        JOIN products p ON im.product_id = p.id
        WHERE p.sku LIKE 'TEST-PROD-%';
    SELECT COUNT(*) INTO alert_count FROM alerts WHERE title LIKE 'Test %';
    
    RAISE NOTICE 'Test data inserted: Users=%, Products=%, Locations=%, Stock=%, Movements=%, Alerts=%', 
        user_count, product_count, location_count, stock_count, movement_count, alert_count;
END $$;

-- Test data summary
SELECT 'Test data inserted successfully' as status;
SELECT 'Test data is ready for automated testing' as message;