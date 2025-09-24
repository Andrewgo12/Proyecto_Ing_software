-- Migration: 009_create_indexes.sql
-- Description: Create additional performance indexes for the inventory system
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- ==================== PERFORMANCE INDEXES ====================

-- Users table additional indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_last_login ON users(last_login_at DESC) WHERE last_login_at IS NOT NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email_verified ON users(email_verified, created_at) WHERE email_verified = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_locked ON users(locked_until) WHERE locked_until IS NOT NULL AND locked_until > CURRENT_TIMESTAMP;

-- Products table additional indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_price_range ON products(unit_price) WHERE is_active = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_trackable_active ON products(is_trackable, is_active) WHERE is_trackable = true AND is_active = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_reorder_needed ON products(reorder_point, min_stock_level) WHERE reorder_point IS NOT NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_expiry_tracking ON products(id) WHERE is_active = true; -- For products that track expiry

-- Categories table additional indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_categories_hierarchy ON categories(parent_id, level, sort_order) WHERE is_active = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_categories_root ON categories(level, sort_order) WHERE parent_id IS NULL AND is_active = true;

-- Locations table additional indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_locations_manager_active ON locations(manager_id) WHERE is_active = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_locations_type_active ON locations(type, is_active) WHERE is_active = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_locations_default_active ON locations(is_default) WHERE is_default = true AND is_active = true;

-- Stock levels table additional indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_reorder_needed ON stock_levels(product_id, location_id) 
    WHERE reorder_point IS NOT NULL AND quantity <= reorder_point;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_cycle_count ON stock_levels(cycle_count_due_date) 
    WHERE cycle_count_due_date IS NOT NULL AND cycle_count_due_date <= CURRENT_DATE;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_abc_velocity ON stock_levels(abc_classification, velocity_classification) 
    WHERE abc_classification IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_value ON stock_levels(total_value DESC) 
    WHERE total_value > 0;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_last_movement ON stock_levels(last_movement_date DESC) 
    WHERE last_movement_date IS NOT NULL;

-- Inventory movements table additional indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inventory_movements_cost_analysis ON inventory_movements(product_id, processed_at, unit_cost) 
    WHERE unit_cost IS NOT NULL AND movement_status = 'completed';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inventory_movements_batch_lot ON inventory_movements(batch_number, lot_number) 
    WHERE batch_number IS NOT NULL OR lot_number IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inventory_movements_expiry ON inventory_movements(expiry_date) 
    WHERE expiry_date IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inventory_movements_transfers ON inventory_movements(location_id, destination_location_id, processed_at) 
    WHERE movement_type = 'transfer' AND movement_status = 'completed';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inventory_movements_monthly ON inventory_movements(DATE_TRUNC('month', processed_at), movement_type) 
    WHERE movement_status = 'completed';

-- Alerts table additional indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_expiry_tracking ON alerts(expiry_date, alert_type) 
    WHERE alert_type IN ('expiry_warning', 'expired') AND status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_escalation ON alerts(escalation_level, created_at) 
    WHERE escalation_level > 0 AND status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_notification_queue ON alerts(notification_sent, notification_count, created_at) 
    WHERE status = 'active' AND notification_sent = false;

-- Suppliers table additional indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_suppliers_performance ON suppliers(overall_rating DESC, preferred_supplier) 
    WHERE status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_suppliers_contract_expiry ON suppliers(contract_end_date) 
    WHERE contract_end_date IS NOT NULL AND status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_suppliers_payment_terms ON suppliers(payment_terms, credit_days) 
    WHERE status = 'active';

-- ==================== COMPOSITE INDEXES FOR COMPLEX QUERIES ====================

-- Product search and filtering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_search_filter ON products(category_id, is_active, unit_price) 
    WHERE is_active = true;

-- Stock analysis by location and product
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_analysis ON stock_levels(location_id, abc_classification, velocity_classification, quantity);

-- Movement analysis by time periods
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_time_analysis ON inventory_movements(
    DATE_TRUNC('day', processed_at), 
    movement_type, 
    location_id
) WHERE movement_status = 'completed';

-- Alert management and reporting
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_management ON alerts(
    status, 
    alert_type, 
    severity, 
    requires_action, 
    created_at DESC
);

-- Supplier performance analysis
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_supplier_performance ON suppliers(
    status, 
    supplier_type, 
    overall_rating DESC, 
    last_order_date DESC
) WHERE status = 'active';

-- ==================== PARTIAL INDEXES FOR SPECIFIC CONDITIONS ====================

-- Active products with tracking enabled
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_active_trackable ON products(id, name, sku) 
    WHERE is_active = true AND is_trackable = true;

-- Products needing reorder
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_reorder_candidates ON products(id, name, reorder_point, reorder_quantity) 
    WHERE is_active = true AND is_trackable = true AND reorder_point IS NOT NULL;

-- Stock levels with alerts
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_with_alerts ON stock_levels(product_id, location_id, quantity, min_stock) 
    WHERE min_stock IS NOT NULL AND quantity <= min_stock;

-- Recent movements for audit
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_recent ON inventory_movements(processed_at DESC, processed_by, movement_type) 
    WHERE processed_at >= CURRENT_DATE - INTERVAL '30 days' AND movement_status = 'completed';

-- Pending alerts requiring action
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_action_required ON alerts(created_at DESC, severity, escalation_level) 
    WHERE status = 'active' AND requires_action = true;

-- Expired or expiring products
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_expiry_tracking ON inventory_movements(expiry_date, product_id, location_id) 
    WHERE expiry_date IS NOT NULL AND movement_type IN ('in', 'transfer') AND movement_status = 'completed';

-- ==================== FUNCTIONAL INDEXES ====================

-- Case-insensitive product search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_name_lower ON products(LOWER(name)) WHERE is_active = true;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_sku_lower ON products(LOWER(sku)) WHERE is_active = true;

-- Case-insensitive supplier search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_suppliers_name_lower ON suppliers(LOWER(company_name)) WHERE status = 'active';

-- Date-based partitioning helpers
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_year_month ON inventory_movements(
    EXTRACT(YEAR FROM processed_at), 
    EXTRACT(MONTH FROM processed_at),
    movement_type
) WHERE movement_status = 'completed';

-- ==================== EXPRESSION INDEXES ====================

-- Available quantity calculation
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_available_calc ON stock_levels((quantity - reserved_quantity)) 
    WHERE (quantity - reserved_quantity) >= 0;

-- Days since last movement
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_days_since_movement ON stock_levels(
    (EXTRACT(DAY FROM CURRENT_TIMESTAMP - last_movement_date))::INTEGER
) WHERE last_movement_date IS NOT NULL;

-- Movement value calculation
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_value_calc ON inventory_movements(
    (ABS(quantity) * COALESCE(unit_cost, 0))
) WHERE unit_cost IS NOT NULL AND movement_status = 'completed';

-- ==================== COVERING INDEXES ====================

-- Product list with stock info (covering index)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_with_stock_info ON products(id) 
INCLUDE (sku, name, unit_price, is_active, category_id) 
WHERE is_active = true AND is_trackable = true;

-- Stock levels with product info (covering index)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_with_product_info ON stock_levels(product_id, location_id) 
INCLUDE (quantity, reserved_quantity, min_stock, max_stock, last_movement_date);

-- Movement history with details (covering index)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_with_details ON inventory_movements(product_id, processed_at DESC) 
INCLUDE (movement_type, quantity, unit_cost, reference_number, processed_by) 
WHERE movement_status = 'completed';

-- ==================== STATISTICS AND MAINTENANCE ====================

-- Update table statistics for better query planning
ANALYZE users;
ANALYZE products;
ANALYZE categories;
ANALYZE locations;
ANALYZE stock_levels;
ANALYZE inventory_movements;
ANALYZE alerts;
ANALYZE suppliers;
ANALYZE supplier_contacts;

-- Create function to update statistics regularly
CREATE OR REPLACE FUNCTION update_inventory_statistics()
RETURNS void AS $$
BEGIN
    -- Update statistics for all main tables
    ANALYZE users;
    ANALYZE products;
    ANALYZE categories;
    ANALYZE locations;
    ANALYZE stock_levels;
    ANALYZE inventory_movements;
    ANALYZE alerts;
    ANALYZE suppliers;
    ANALYZE supplier_contacts;
    
    -- Log the update
    RAISE NOTICE 'Inventory system statistics updated at %', CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Comment on the statistics function
COMMENT ON FUNCTION update_inventory_statistics() IS 'Updates table statistics for better query performance';

-- ==================== INDEX MONITORING ====================

-- Create view to monitor index usage
CREATE VIEW index_usage_stats AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    idx_scan,
    CASE 
        WHEN idx_scan = 0 THEN 'Never used'
        WHEN idx_scan < 100 THEN 'Rarely used'
        WHEN idx_scan < 1000 THEN 'Moderately used'
        ELSE 'Frequently used'
    END as usage_category
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

COMMENT ON VIEW index_usage_stats IS 'Monitor index usage patterns for optimization';

-- Create view to identify missing indexes
CREATE VIEW potential_missing_indexes AS
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    CASE 
        WHEN seq_scan > idx_scan AND seq_tup_read > 10000 THEN 'High'
        WHEN seq_scan > idx_scan AND seq_tup_read > 1000 THEN 'Medium'
        ELSE 'Low'
    END as missing_index_priority
FROM pg_stat_user_tables 
WHERE schemaname = 'public'
    AND seq_scan > 0
ORDER BY seq_tup_read DESC;

COMMENT ON VIEW potential_missing_indexes IS 'Identify tables that might benefit from additional indexes';

-- ==================== MAINTENANCE RECOMMENDATIONS ====================

-- Create function to get index maintenance recommendations
CREATE OR REPLACE FUNCTION get_index_maintenance_recommendations()
RETURNS TABLE(
    recommendation_type TEXT,
    table_name TEXT,
    index_name TEXT,
    description TEXT,
    priority TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Unused indexes
    SELECT 
        'UNUSED_INDEX'::TEXT,
        i.tablename::TEXT,
        i.indexname::TEXT,
        'Index has never been used and may be dropped'::TEXT,
        'Medium'::TEXT
    FROM pg_stat_user_indexes i
    WHERE i.schemaname = 'public' 
        AND i.idx_scan = 0
        AND i.indexname NOT LIKE '%_pkey'
    
    UNION ALL
    
    -- Tables with high sequential scans
    SELECT 
        'MISSING_INDEX'::TEXT,
        t.tablename::TEXT,
        NULL::TEXT,
        'Table has high sequential scan ratio, consider adding indexes'::TEXT,
        CASE 
            WHEN t.seq_tup_read > 100000 THEN 'High'
            WHEN t.seq_tup_read > 10000 THEN 'Medium'
            ELSE 'Low'
        END::TEXT
    FROM pg_stat_user_tables t
    WHERE t.schemaname = 'public'
        AND t.seq_scan > COALESCE(t.idx_scan, 0)
        AND t.seq_tup_read > 1000
    
    ORDER BY 5 DESC, 2, 3;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_index_maintenance_recommendations() IS 'Provides recommendations for index maintenance and optimization';

-- Migration completed successfully
SELECT 'Migration 009_create_indexes.sql completed successfully' as status;
SELECT 'Created ' || COUNT(*) || ' additional indexes for performance optimization' as summary
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_%';