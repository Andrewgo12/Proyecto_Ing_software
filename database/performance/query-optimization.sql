-- Performance: query-optimization.sql
-- Description: Query optimization guidelines and examples for Sistema de Inventario PYMES
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- ==================== QUERY OPTIMIZATION GUIDELINES ====================

-- This file contains optimized queries and performance best practices
-- for the Sistema de Inventario PYMES database

-- ==================== STOCK LEVEL QUERIES ====================

-- Optimized query for current stock levels with alerts
-- Uses covering indexes and efficient joins
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    p.id,
    p.sku,
    p.name,
    l.name as location_name,
    sl.quantity,
    sl.available_quantity,
    sl.min_stock,
    CASE 
        WHEN sl.quantity <= 0 THEN 'OUT_OF_STOCK'
        WHEN sl.quantity <= COALESCE(sl.min_stock, 0) THEN 'LOW_STOCK'
        ELSE 'NORMAL'
    END as stock_status
FROM products p
JOIN stock_levels sl ON p.id = sl.product_id
JOIN locations l ON sl.location_id = l.id
WHERE p.is_active = true 
    AND p.is_trackable = true
    AND l.is_active = true
    AND (sl.quantity <= COALESCE(sl.min_stock, 0) OR sl.quantity <= 0)
ORDER BY 
    CASE 
        WHEN sl.quantity <= 0 THEN 1
        WHEN sl.quantity <= COALESCE(sl.min_stock, 0) THEN 2
        ELSE 3
    END,
    sl.quantity ASC;

-- Optimized inventory valuation query
-- Uses materialized aggregation for better performance
EXPLAIN (ANALYZE, BUFFERS)
WITH location_totals AS (
    SELECT 
        l.id as location_id,
        l.name as location_name,
        COUNT(sl.id) as product_count,
        SUM(sl.quantity) as total_quantity,
        SUM(sl.total_value) as total_value
    FROM locations l
    LEFT JOIN stock_levels sl ON l.id = sl.location_id
    WHERE l.is_active = true
    GROUP BY l.id, l.name
)
SELECT 
    location_id,
    location_name,
    product_count,
    total_quantity,
    total_value,
    CASE 
        WHEN total_quantity > 0 THEN total_value / total_quantity
        ELSE 0
    END as avg_unit_value
FROM location_totals
WHERE product_count > 0
ORDER BY total_value DESC;

-- ==================== MOVEMENT HISTORY QUERIES ====================

-- Optimized movement history with pagination
-- Uses index on (product_id, processed_at) for efficient sorting
CREATE OR REPLACE FUNCTION get_movement_history_optimized(
    p_product_id UUID DEFAULT NULL,
    p_location_id UUID DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_offset INTEGER DEFAULT 0,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE(
    movement_id UUID,
    movement_number VARCHAR(50),
    product_sku VARCHAR(50),
    movement_type movement_type,
    quantity DECIMAL(12,3),
    processed_at TIMESTAMP,
    processed_by_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        im.id,
        im.movement_number,
        p.sku,
        im.movement_type,
        im.quantity,
        im.processed_at,
        u.first_name || ' ' || u.last_name
    FROM inventory_movements im
    JOIN products p ON im.product_id = p.id
    JOIN users u ON im.processed_by = u.id
    WHERE im.movement_status = 'completed'
        AND (p_product_id IS NULL OR im.product_id = p_product_id)
        AND (p_location_id IS NULL OR im.location_id = p_location_id)
        AND (p_start_date IS NULL OR DATE(im.processed_at) >= p_start_date)
        AND (p_end_date IS NULL OR DATE(im.processed_at) <= p_end_date)
    ORDER BY im.processed_at DESC
    OFFSET p_offset
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Optimized daily movement summary
-- Uses date truncation index for efficient grouping
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    DATE_TRUNC('day', processed_at) as movement_date,
    movement_type,
    COUNT(*) as transaction_count,
    SUM(ABS(quantity)) as total_quantity,
    SUM(COALESCE(total_cost, 0)) as total_value,
    COUNT(DISTINCT product_id) as unique_products
FROM inventory_movements
WHERE movement_status = 'completed'
    AND processed_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', processed_at), movement_type
ORDER BY movement_date DESC, movement_type;

-- ==================== PRODUCT PERFORMANCE QUERIES ====================

-- Optimized product sales analysis
-- Uses window functions for efficient ranking
EXPLAIN (ANALYZE, BUFFERS)
WITH product_sales AS (
    SELECT 
        p.id,
        p.sku,
        p.name,
        SUM(CASE WHEN im.movement_type = 'out' AND im.processed_at >= CURRENT_DATE - INTERVAL '30 days' 
                 THEN ABS(im.quantity) ELSE 0 END) as sales_30d,
        SUM(CASE WHEN im.movement_type = 'out' AND im.processed_at >= CURRENT_DATE - INTERVAL '90 days' 
                 THEN ABS(im.quantity) ELSE 0 END) as sales_90d,
        COUNT(CASE WHEN im.movement_type = 'out' AND im.processed_at >= CURRENT_DATE - INTERVAL '30 days' 
                   THEN 1 END) as transactions_30d
    FROM products p
    LEFT JOIN inventory_movements im ON p.id = im.product_id AND im.movement_status = 'completed'
    WHERE p.is_active = true AND p.is_trackable = true
    GROUP BY p.id, p.sku, p.name
),
ranked_products AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY sales_30d DESC) as sales_rank,
        CASE 
            WHEN sales_30d > 50 THEN 'fast'
            WHEN sales_30d > 10 THEN 'medium'
            WHEN sales_90d > 0 THEN 'slow'
            ELSE 'dead'
        END as velocity_class
    FROM product_sales
)
SELECT 
    sku,
    name,
    sales_30d,
    sales_90d,
    transactions_30d,
    velocity_class,
    sales_rank
FROM ranked_products
WHERE sales_rank <= 100  -- Top 100 products
ORDER BY sales_rank;

-- ==================== SUPPLIER PERFORMANCE QUERIES ====================

-- Optimized supplier performance analysis
-- Uses efficient aggregation with conditional sums
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    s.id,
    s.supplier_code,
    s.company_name,
    s.overall_rating,
    COUNT(im.id) as total_orders,
    SUM(im.total_cost) as total_value,
    COUNT(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '90 days' THEN 1 END) as recent_orders,
    SUM(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '90 days' THEN im.total_cost END) as recent_value,
    AVG(im.unit_cost) as avg_unit_cost,
    MAX(im.processed_at) as last_order_date
FROM suppliers s
LEFT JOIN inventory_movements im ON s.id = im.supplier_id 
    AND im.movement_type = 'in' 
    AND im.movement_status = 'completed'
WHERE s.status = 'active'
GROUP BY s.id, s.supplier_code, s.company_name, s.overall_rating
HAVING COUNT(im.id) > 0
ORDER BY recent_value DESC NULLS LAST;

-- ==================== ALERT QUERIES ====================

-- Optimized active alerts query
-- Uses partial index on active alerts
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    a.id,
    a.alert_type,
    a.severity,
    a.title,
    p.sku as product_sku,
    l.name as location_name,
    a.current_value,
    a.threshold_value,
    a.created_at,
    EXTRACT(HOUR FROM CURRENT_TIMESTAMP - a.created_at) as age_hours
FROM alerts a
LEFT JOIN products p ON a.product_id = p.id
LEFT JOIN locations l ON a.location_id = l.id
WHERE a.status = 'active'
ORDER BY 
    CASE a.severity 
        WHEN 'critical' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        WHEN 'low' THEN 4 
    END,
    a.created_at ASC;

-- ==================== SEARCH QUERIES ====================

-- Optimized product search with full-text search
-- Uses GIN index on tsvector for fast text search
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    p.id,
    p.sku,
    p.name,
    p.unit_price,
    c.name as category_name,
    ts_rank(to_tsvector('spanish', p.name || ' ' || COALESCE(p.description, '')), 
            plainto_tsquery('spanish', 'laptop')) as rank
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.is_active = true
    AND to_tsvector('spanish', p.name || ' ' || COALESCE(p.description, '')) 
        @@ plainto_tsquery('spanish', 'laptop')
ORDER BY rank DESC, p.name
LIMIT 20;

-- Optimized SKU/barcode lookup
-- Uses unique indexes for instant lookup
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    p.id,
    p.sku,
    p.name,
    p.unit_price,
    p.barcode,
    SUM(sl.quantity) as total_stock
FROM products p
LEFT JOIN stock_levels sl ON p.id = sl.product_id
WHERE p.is_active = true
    AND (p.sku ILIKE '%ABC123%' OR p.barcode = '1234567890123')
GROUP BY p.id, p.sku, p.name, p.unit_price, p.barcode
ORDER BY p.name;

-- ==================== REPORTING QUERIES ====================

-- Optimized inventory aging report
-- Uses efficient date calculations and window functions
EXPLAIN (ANALYZE, BUFFERS)
WITH movement_ages AS (
    SELECT 
        im.product_id,
        im.location_id,
        im.quantity,
        im.processed_at,
        EXTRACT(DAY FROM CURRENT_DATE - DATE(im.processed_at)) as age_days,
        ROW_NUMBER() OVER (PARTITION BY im.product_id, im.location_id ORDER BY im.processed_at DESC) as rn
    FROM inventory_movements im
    WHERE im.movement_type = 'in' 
        AND im.movement_status = 'completed'
        AND im.quantity > 0
)
SELECT 
    p.sku,
    p.name,
    l.name as location_name,
    sl.quantity,
    ma.age_days,
    CASE 
        WHEN ma.age_days <= 30 THEN 'Fresh (0-30 days)'
        WHEN ma.age_days <= 90 THEN 'Recent (31-90 days)'
        WHEN ma.age_days <= 180 THEN 'Aging (91-180 days)'
        ELSE 'Old (180+ days)'
    END as age_category,
    sl.total_value
FROM products p
JOIN stock_levels sl ON p.id = sl.product_id
JOIN locations l ON sl.location_id = l.id
LEFT JOIN movement_ages ma ON p.id = ma.product_id AND l.id = ma.location_id AND ma.rn = 1
WHERE p.is_active = true 
    AND sl.quantity > 0
ORDER BY ma.age_days DESC NULLS LAST, sl.total_value DESC;

-- ==================== PERFORMANCE MONITORING QUERIES ====================

-- Query to identify slow queries
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements 
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_time DESC 
LIMIT 10;

-- Query to identify missing indexes
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    seq_tup_read / seq_scan as avg_seq_read
FROM pg_stat_user_tables 
WHERE seq_scan > 0
    AND seq_tup_read / seq_scan > 1000
ORDER BY seq_tup_read DESC;

-- Query to check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
ORDER BY idx_scan DESC;

-- ==================== OPTIMIZATION RECOMMENDATIONS ====================

/*
PERFORMANCE OPTIMIZATION RECOMMENDATIONS:

1. INDEXING STRATEGY:
   - Use covering indexes for frequently accessed columns
   - Create partial indexes for filtered queries
   - Use composite indexes for multi-column WHERE clauses
   - Consider GIN indexes for JSONB and full-text search

2. QUERY OPTIMIZATION:
   - Use LIMIT with ORDER BY for pagination
   - Avoid SELECT * in production queries
   - Use EXISTS instead of IN for subqueries
   - Use window functions instead of correlated subqueries

3. DATA ACCESS PATTERNS:
   - Batch operations when possible
   - Use prepared statements for repeated queries
   - Implement connection pooling
   - Cache frequently accessed data

4. MAINTENANCE:
   - Regular VACUUM and ANALYZE
   - Monitor query performance with pg_stat_statements
   - Update table statistics regularly
   - Monitor index usage and remove unused indexes

5. SPECIFIC OPTIMIZATIONS:
   - Use stock_alerts view instead of complex joins
   - Implement materialized views for heavy reporting queries
   - Use partitioning for large historical tables
   - Consider read replicas for reporting workloads
*/

-- ==================== EXAMPLE OPTIMIZED QUERIES ====================

-- Fast product lookup by SKU (uses unique index)
SELECT p.*, sl.quantity 
FROM products p 
LEFT JOIN stock_levels sl ON p.id = sl.product_id 
WHERE p.sku = $1 AND p.is_active = true;

-- Fast location stock summary (uses covering index)
SELECT 
    COUNT(*) as product_count,
    SUM(quantity) as total_quantity,
    SUM(total_value) as total_value
FROM stock_levels 
WHERE location_id = $1;

-- Fast recent movements (uses composite index)
SELECT * FROM inventory_movements 
WHERE product_id = $1 
    AND processed_at >= $2 
    AND movement_status = 'completed'
ORDER BY processed_at DESC 
LIMIT 50;

-- Fast alert count by severity (uses partial index)
SELECT severity, COUNT(*) 
FROM alerts 
WHERE status = 'active' 
GROUP BY severity;

SELECT 'Query optimization examples loaded successfully' as status;