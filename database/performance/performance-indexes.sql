-- Performance: performance-indexes.sql
-- Description: Additional performance indexes for Sistema de Inventario PYMES
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- ==================== PERFORMANCE ANALYSIS ====================

-- This file contains additional performance indexes beyond the basic ones
-- created in the main migrations. These are specifically tuned for common
-- query patterns and reporting needs.

-- ==================== COVERING INDEXES ====================

-- Covering index for product list with stock info
-- Includes frequently accessed columns to avoid table lookups
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_list_covering 
ON products (is_active, is_trackable, category_id) 
INCLUDE (id, sku, name, unit_price, cost_price, created_at)
WHERE is_active = true AND is_trackable = true;

-- Covering index for stock levels with product info
-- Optimizes stock reports and alerts
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_reporting_covering 
ON stock_levels (location_id, product_id) 
INCLUDE (quantity, available_quantity, reserved_quantity, min_stock, max_stock, total_value, last_movement_date)
WHERE quantity IS NOT NULL;

-- Covering index for movement history
-- Optimizes movement queries with product and user info
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_history_covering 
ON inventory_movements (product_id, processed_at DESC, movement_status) 
INCLUDE (id, movement_number, movement_type, quantity, unit_cost, reference_number, processed_by)
WHERE movement_status = 'completed';

-- ==================== PARTIAL INDEXES ====================

-- Index for active products only
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_active_only 
ON products (category_id, name, sku) 
WHERE is_active = true AND is_trackable = true;

-- Index for low stock alerts
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_low_stock 
ON stock_levels (product_id, location_id, quantity, min_stock) 
WHERE min_stock IS NOT NULL AND quantity <= min_stock;

-- Index for out of stock items
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_out_of_stock 
ON stock_levels (product_id, location_id, last_movement_date) 
WHERE quantity <= 0;

-- Index for overstock items
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_overstock 
ON stock_levels (product_id, location_id, quantity, max_stock) 
WHERE max_stock IS NOT NULL AND quantity > max_stock;

-- Index for recent movements (last 90 days)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_recent 
ON inventory_movements (processed_at DESC, movement_type, location_id, product_id) 
WHERE processed_at >= CURRENT_DATE - INTERVAL '90 days' AND movement_status = 'completed';

-- Index for pending movements
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_pending 
ON inventory_movements (created_at DESC, movement_type, location_id) 
WHERE movement_status IN ('pending', 'processing');

-- Index for active alerts requiring action
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_action_required 
ON alerts (severity, created_at DESC, escalation_level) 
WHERE status = 'active' AND requires_action = true;

-- Index for unread notifications
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_unread 
ON notifications (recipient_user_id, created_at DESC) 
WHERE is_read = false AND expires_at > CURRENT_TIMESTAMP;

-- ==================== EXPRESSION INDEXES ====================

-- Index for case-insensitive product name search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_name_lower 
ON products (LOWER(name)) 
WHERE is_active = true;

-- Index for case-insensitive SKU search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_sku_lower 
ON products (LOWER(sku)) 
WHERE is_active = true;

-- Index for available quantity calculation
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_available_calc 
ON stock_levels ((quantity - reserved_quantity), product_id, location_id) 
WHERE (quantity - reserved_quantity) >= 0;

-- Index for stock value calculation
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_value_calc 
ON stock_levels ((quantity * average_cost), location_id) 
WHERE quantity > 0 AND average_cost > 0;

-- Index for days since last movement
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_days_since_movement 
ON stock_levels ((EXTRACT(DAY FROM CURRENT_TIMESTAMP - last_movement_date))::INTEGER, product_id) 
WHERE last_movement_date IS NOT NULL;

-- Index for movement value calculation
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_value_calc 
ON inventory_movements ((ABS(quantity) * unit_cost), processed_at DESC) 
WHERE unit_cost IS NOT NULL AND movement_status = 'completed';

-- ==================== COMPOSITE INDEXES FOR COMPLEX QUERIES ====================

-- Index for product search with category and price range
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_search_composite 
ON products (category_id, unit_price, is_active, name) 
WHERE is_active = true;

-- Index for stock analysis by ABC classification
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_levels_abc_analysis 
ON stock_levels (abc_classification, velocity_classification, total_value DESC, location_id) 
WHERE abc_classification IS NOT NULL;

-- Index for movement analysis by time and type
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_time_type_analysis 
ON inventory_movements (
    DATE_TRUNC('month', processed_at), 
    movement_type, 
    location_id, 
    total_cost DESC
) WHERE movement_status = 'completed';

-- Index for supplier performance analysis
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_supplier_performance 
ON inventory_movements (
    supplier_id, 
    processed_at DESC, 
    movement_type, 
    total_cost
) WHERE supplier_id IS NOT NULL AND movement_status = 'completed';

-- Index for user activity analysis
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_user_activity 
ON inventory_movements (
    processed_by, 
    processed_at DESC, 
    movement_type
) WHERE movement_status = 'completed';

-- ==================== JSONB INDEXES ====================

-- Index for product tags search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_tags_gin 
ON products USING gin(tags) 
WHERE tags IS NOT NULL;

-- Index for product custom fields search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_custom_fields_gin 
ON products USING gin(custom_fields) 
WHERE custom_fields IS NOT NULL;

-- Index for supplier certifications search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_suppliers_certifications_gin 
ON suppliers USING gin(certifications) 
WHERE certifications IS NOT NULL;

-- Index for alert reference data search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_reference_data_gin 
ON alerts USING gin(reference_data) 
WHERE reference_data IS NOT NULL;

-- Index for location operating hours
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_locations_operating_hours_gin 
ON locations USING gin(operating_hours) 
WHERE operating_hours IS NOT NULL;

-- ==================== FULL-TEXT SEARCH INDEXES ====================

-- Full-text search index for products (Spanish)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_fts_spanish 
ON products USING gin(to_tsvector('spanish', name || ' ' || COALESCE(description, ''))) 
WHERE is_active = true;

-- Full-text search index for suppliers (Spanish)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_suppliers_fts_spanish 
ON suppliers USING gin(to_tsvector('spanish', company_name || ' ' || COALESCE(trade_name, '') || ' ' || COALESCE(industry, ''))) 
WHERE status = 'active';

-- Full-text search index for categories (Spanish)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_categories_fts_spanish 
ON categories USING gin(to_tsvector('spanish', name || ' ' || COALESCE(description, ''))) 
WHERE is_active = true;

-- ==================== SPECIALIZED REPORTING INDEXES ====================

-- Index for inventory valuation reports
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_valuation_report 
ON stock_levels (location_id, total_value DESC, quantity) 
WHERE total_value > 0;

-- Index for ABC analysis reports
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_abc_report 
ON stock_levels (abc_classification, total_value DESC, velocity_classification) 
WHERE abc_classification IS NOT NULL;

-- Index for movement velocity reports
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_velocity_report 
ON inventory_movements (
    product_id, 
    movement_type, 
    processed_at DESC
) WHERE movement_type IN ('in', 'out') AND movement_status = 'completed';

-- Index for supplier delivery performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_delivery_performance 
ON inventory_movements (
    supplier_id, 
    processed_at, 
    external_document_date
) WHERE supplier_id IS NOT NULL AND movement_type = 'in' AND movement_status = 'completed';

-- Index for cycle count due dates
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stock_cycle_count_due 
ON stock_levels (cycle_count_due_date, location_id, product_id) 
WHERE cycle_count_due_date IS NOT NULL AND cycle_count_due_date <= CURRENT_DATE + INTERVAL '7 days';

-- ==================== AUDIT AND MONITORING INDEXES ====================

-- Index for audit log queries by table and date
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_log_table_date 
ON audit_log (table_name, created_at DESC, operation);

-- Index for audit log queries by user and date
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_log_user_date 
ON audit_log (user_id, created_at DESC, table_name) 
WHERE user_id IS NOT NULL;

-- Index for audit log queries by record
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_log_record 
ON audit_log (table_name, record_id, created_at DESC);

-- ==================== MAINTENANCE INDEXES ====================

-- Index for cleanup operations (old audit logs)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_log_cleanup 
ON audit_log (created_at) 
WHERE created_at < CURRENT_DATE - INTERVAL '1 year';

-- Index for cleanup operations (old notifications)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_cleanup 
ON notifications (expires_at, created_at) 
WHERE expires_at < CURRENT_TIMESTAMP OR created_at < CURRENT_DATE - INTERVAL '90 days';

-- Index for cleanup operations (resolved alerts)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_cleanup 
ON alerts (status, updated_at) 
WHERE status IN ('resolved', 'dismissed') AND updated_at < CURRENT_DATE - INTERVAL '6 months';

-- ==================== UNIQUE CONSTRAINTS AS INDEXES ====================

-- Ensure unique alert codes
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_code_unique 
ON alerts (alert_code);

-- Ensure unique movement numbers
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_movements_number_unique 
ON inventory_movements (movement_number);

-- Ensure unique supplier codes
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_suppliers_code_unique 
ON suppliers (supplier_code);

-- Ensure unique location codes
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_locations_code_unique 
ON locations (code);

-- ==================== PERFORMANCE MONITORING ====================

-- Function to analyze index usage
CREATE OR REPLACE FUNCTION analyze_index_usage()
RETURNS TABLE(
    schemaname TEXT,
    tablename TEXT,
    indexname TEXT,
    index_size TEXT,
    index_scans BIGINT,
    tuples_read BIGINT,
    tuples_fetched BIGINT,
    usage_ratio NUMERIC,
    recommendation TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.schemaname::TEXT,
        s.tablename::TEXT,
        s.indexname::TEXT,
        pg_size_pretty(pg_relation_size(s.indexrelid))::TEXT as index_size,
        s.idx_scan,
        s.idx_tup_read,
        s.idx_tup_fetch,
        CASE 
            WHEN s.idx_scan = 0 THEN 0
            ELSE ROUND((s.idx_tup_fetch::NUMERIC / s.idx_scan), 2)
        END as usage_ratio,
        CASE 
            WHEN s.idx_scan = 0 THEN 'Consider dropping - never used'
            WHEN s.idx_scan < 100 THEN 'Low usage - review necessity'
            WHEN s.idx_tup_fetch::NUMERIC / s.idx_scan < 1 THEN 'Poor selectivity - review'
            ELSE 'Good usage'
        END::TEXT as recommendation
    FROM pg_stat_user_indexes s
    WHERE s.schemaname = 'public'
    ORDER BY s.idx_scan DESC, pg_relation_size(s.indexrelid) DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get table statistics
CREATE OR REPLACE FUNCTION get_table_statistics()
RETURNS TABLE(
    schemaname TEXT,
    tablename TEXT,
    table_size TEXT,
    row_count BIGINT,
    seq_scans BIGINT,
    seq_tup_read BIGINT,
    idx_scans BIGINT,
    idx_tup_fetch BIGINT,
    n_tup_ins BIGINT,
    n_tup_upd BIGINT,
    n_tup_del BIGINT,
    last_vacuum TIMESTAMP,
    last_analyze TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.schemaname::TEXT,
        s.tablename::TEXT,
        pg_size_pretty(pg_total_relation_size(s.relid))::TEXT,
        s.n_tup_ins + s.n_tup_upd + s.n_tup_del as row_count,
        s.seq_scan,
        s.seq_tup_read,
        s.idx_scan,
        s.idx_tup_fetch,
        s.n_tup_ins,
        s.n_tup_upd,
        s.n_tup_del,
        s.last_vacuum,
        s.last_analyze
    FROM pg_stat_user_tables s
    WHERE s.schemaname = 'public'
    ORDER BY pg_total_relation_size(s.relid) DESC;
END;
$$ LANGUAGE plpgsql;

-- ==================== INDEX MAINTENANCE ====================

-- Function to reindex all tables
CREATE OR REPLACE FUNCTION reindex_all_tables()
RETURNS TEXT AS $$
DECLARE
    table_record RECORD;
    result_text TEXT := '';
BEGIN
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'REINDEX TABLE ' || quote_ident(table_record.tablename);
        result_text := result_text || 'Reindexed table: ' || table_record.tablename || E'\n';
    END LOOP;
    
    RETURN result_text || 'All tables reindexed successfully';
END;
$$ LANGUAGE plpgsql;

-- Function to update table statistics
CREATE OR REPLACE FUNCTION update_all_statistics()
RETURNS TEXT AS $$
DECLARE
    table_record RECORD;
    result_text TEXT := '';
BEGIN
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'ANALYZE ' || quote_ident(table_record.tablename);
        result_text := result_text || 'Analyzed table: ' || table_record.tablename || E'\n';
    END LOOP;
    
    RETURN result_text || 'All table statistics updated successfully';
END;
$$ LANGUAGE plpgsql;

-- ==================== COMMENTS ====================

COMMENT ON FUNCTION analyze_index_usage() IS 'Analyzes index usage patterns and provides recommendations';
COMMENT ON FUNCTION get_table_statistics() IS 'Returns comprehensive table statistics for performance monitoring';
COMMENT ON FUNCTION reindex_all_tables() IS 'Reindexes all tables in the public schema';
COMMENT ON FUNCTION update_all_statistics() IS 'Updates statistics for all tables in the public schema';

-- Performance indexes created successfully
SELECT 'Performance indexes created successfully' as status;
SELECT COUNT(*) || ' additional performance indexes created' as summary 
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_%';