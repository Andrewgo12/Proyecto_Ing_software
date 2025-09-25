-- Schema: views.sql
-- Description: Database views for Sistema de Inventario PYMES
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- ==================== INVENTORY VIEWS ====================

-- Stock alerts view
CREATE OR REPLACE VIEW stock_alerts AS
SELECT 
    sl.id,
    sl.product_id,
    p.sku,
    p.name as product_name,
    sl.location_id,
    l.name as location_name,
    l.code as location_code,
    sl.quantity,
    sl.available_quantity,
    sl.reserved_quantity,
    sl.min_stock,
    sl.max_stock,
    sl.reorder_point,
    CASE 
        WHEN sl.quantity <= 0 THEN 'OUT_OF_STOCK'
        WHEN sl.quantity <= COALESCE(sl.min_stock, 0) THEN 'LOW_STOCK'
        WHEN sl.max_stock IS NOT NULL AND sl.quantity > sl.max_stock THEN 'OVERSTOCK'
        WHEN sl.reorder_point IS NOT NULL AND sl.quantity <= sl.reorder_point THEN 'REORDER_NEEDED'
        ELSE 'NORMAL'
    END as alert_type,
    CASE 
        WHEN sl.quantity <= 0 THEN 'critical'
        WHEN sl.quantity <= COALESCE(sl.min_stock, 0) * 0.5 THEN 'high'
        WHEN sl.quantity <= COALESCE(sl.min_stock, 0) THEN 'medium'
        WHEN sl.max_stock IS NOT NULL AND sl.quantity > sl.max_stock * 1.5 THEN 'medium'
        WHEN sl.max_stock IS NOT NULL AND sl.quantity > sl.max_stock THEN 'low'
        ELSE 'info'
    END as severity,
    sl.last_movement_date,
    EXTRACT(DAY FROM CURRENT_TIMESTAMP - sl.last_movement_date)::INTEGER as days_since_movement,
    sl.total_value,
    sl.updated_at
FROM stock_levels sl
JOIN products p ON sl.product_id = p.id
JOIN locations l ON sl.location_id = l.id
WHERE p.is_active = true 
    AND l.is_active = true
    AND p.is_trackable = true
    AND (
        sl.quantity <= 0 
        OR sl.quantity <= COALESCE(sl.min_stock, 0)
        OR (sl.max_stock IS NOT NULL AND sl.quantity > sl.max_stock)
        OR (sl.reorder_point IS NOT NULL AND sl.quantity <= sl.reorder_point)
    );

-- Current stock summary view
CREATE OR REPLACE VIEW current_stock_summary AS
SELECT 
    p.id as product_id,
    p.sku,
    p.name as product_name,
    p.unit_price,
    p.cost_price,
    c.name as category_name,
    COUNT(sl.id) as locations_count,
    SUM(sl.quantity) as total_quantity,
    SUM(sl.available_quantity) as total_available,
    SUM(sl.reserved_quantity) as total_reserved,
    SUM(sl.allocated_quantity) as total_allocated,
    SUM(sl.total_value) as total_value,
    AVG(sl.average_cost) as avg_cost,
    MIN(sl.last_movement_date) as oldest_movement,
    MAX(sl.last_movement_date) as latest_movement,
    COUNT(CASE WHEN sl.quantity <= COALESCE(sl.min_stock, 0) THEN 1 END) as low_stock_locations,
    COUNT(CASE WHEN sl.quantity <= 0 THEN 1 END) as out_of_stock_locations
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN stock_levels sl ON p.id = sl.product_id
WHERE p.is_active = true AND p.is_trackable = true
GROUP BY p.id, p.sku, p.name, p.unit_price, p.cost_price, c.name;

-- Movement summary view
CREATE OR REPLACE VIEW movement_summary AS
SELECT 
    DATE_TRUNC('day', processed_at) as movement_date,
    movement_type,
    location_id,
    l.name as location_name,
    l.code as location_code,
    COUNT(*) as movement_count,
    SUM(ABS(quantity)) as total_quantity,
    SUM(total_cost) as total_value,
    COUNT(DISTINCT product_id) as unique_products,
    COUNT(DISTINCT processed_by) as unique_users
FROM inventory_movements im
JOIN locations l ON im.location_id = l.id
WHERE movement_status = 'completed'
GROUP BY DATE_TRUNC('day', processed_at), movement_type, location_id, l.name, l.code
ORDER BY movement_date DESC, movement_type;

-- Product performance view
CREATE OR REPLACE VIEW product_performance AS
SELECT 
    p.id as product_id,
    p.sku,
    p.name as product_name,
    p.unit_price,
    p.cost_price,
    c.name as category_name,
    
    -- Stock metrics
    COALESCE(SUM(sl.quantity), 0) as current_stock,
    COALESCE(SUM(sl.total_value), 0) as stock_value,
    
    -- Movement metrics (last 30 days)
    COALESCE(SUM(CASE WHEN im.movement_type = 'out' AND im.processed_at >= CURRENT_DATE - INTERVAL '30 days' THEN ABS(im.quantity) END), 0) as sales_30d,
    COALESCE(SUM(CASE WHEN im.movement_type = 'in' AND im.processed_at >= CURRENT_DATE - INTERVAL '30 days' THEN im.quantity END), 0) as purchases_30d,
    COUNT(CASE WHEN im.movement_type = 'out' AND im.processed_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as sales_transactions_30d,
    
    -- Movement metrics (last 90 days)
    COALESCE(SUM(CASE WHEN im.movement_type = 'out' AND im.processed_at >= CURRENT_DATE - INTERVAL '90 days' THEN ABS(im.quantity) END), 0) as sales_90d,
    COALESCE(SUM(CASE WHEN im.movement_type = 'in' AND im.processed_at >= CURRENT_DATE - INTERVAL '90 days' THEN im.quantity END), 0) as purchases_90d,
    
    -- Velocity classification
    CASE 
        WHEN COALESCE(SUM(CASE WHEN im.movement_type = 'out' AND im.processed_at >= CURRENT_DATE - INTERVAL '30 days' THEN ABS(im.quantity) END), 0) > 50 THEN 'fast'
        WHEN COALESCE(SUM(CASE WHEN im.movement_type = 'out' AND im.processed_at >= CURRENT_DATE - INTERVAL '30 days' THEN ABS(im.quantity) END), 0) > 10 THEN 'medium'
        WHEN COALESCE(SUM(CASE WHEN im.movement_type = 'out' AND im.processed_at >= CURRENT_DATE - INTERVAL '90 days' THEN ABS(im.quantity) END), 0) > 0 THEN 'slow'
        ELSE 'dead'
    END as velocity_classification,
    
    -- Profitability
    CASE 
        WHEN p.cost_price > 0 THEN ((p.unit_price - p.cost_price) / p.cost_price) * 100
        ELSE 0
    END as margin_percentage,
    
    -- Last movement date
    MAX(im.processed_at) as last_movement_date,
    EXTRACT(DAY FROM CURRENT_TIMESTAMP - MAX(im.processed_at))::INTEGER as days_since_movement
    
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN stock_levels sl ON p.id = sl.product_id
LEFT JOIN inventory_movements im ON p.id = im.product_id AND im.movement_status = 'completed'
WHERE p.is_active = true AND p.is_trackable = true
GROUP BY p.id, p.sku, p.name, p.unit_price, p.cost_price, c.name;

-- ==================== SUPPLIER VIEWS ====================

-- Supplier performance view
CREATE OR REPLACE VIEW supplier_performance AS
SELECT 
    s.id as supplier_id,
    s.supplier_code,
    s.company_name,
    s.supplier_type,
    s.status,
    s.preferred_supplier,
    s.lead_time_days,
    s.payment_terms,
    s.delivery_performance_score,
    s.quality_rating,
    s.price_competitiveness_score,
    s.overall_rating,
    
    -- Order metrics
    s.total_orders_count,
    s.total_orders_value,
    s.last_order_date,
    
    -- Recent activity (last 90 days)
    COUNT(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '90 days' THEN 1 END) as recent_orders,
    SUM(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '90 days' THEN im.total_cost END) as recent_value,
    
    -- Performance indicators
    CASE 
        WHEN s.last_order_date >= CURRENT_DATE - INTERVAL '30 days' THEN 'active'
        WHEN s.last_order_date >= CURRENT_DATE - INTERVAL '90 days' THEN 'moderate'
        WHEN s.last_order_date >= CURRENT_DATE - INTERVAL '180 days' THEN 'inactive'
        ELSE 'dormant'
    END as activity_level,
    
    -- Product diversity
    COUNT(DISTINCT im.product_id) as products_supplied
    
FROM suppliers s
LEFT JOIN inventory_movements im ON s.id = im.supplier_id 
    AND im.movement_type = 'in' 
    AND im.movement_status = 'completed'
GROUP BY s.id, s.supplier_code, s.company_name, s.supplier_type, s.status, 
         s.preferred_supplier, s.lead_time_days, s.payment_terms,
         s.delivery_performance_score, s.quality_rating, s.price_competitiveness_score,
         s.overall_rating, s.total_orders_count, s.total_orders_value, s.last_order_date;

-- ==================== ALERT VIEWS ====================

-- Active alerts summary view
CREATE OR REPLACE VIEW active_alerts_summary AS
SELECT 
    alert_type,
    severity,
    COUNT(*) as alert_count,
    COUNT(CASE WHEN requires_action THEN 1 END) as action_required_count,
    MIN(created_at) as oldest_alert,
    MAX(created_at) as newest_alert,
    AVG(EXTRACT(HOUR FROM CURRENT_TIMESTAMP - created_at)) as avg_age_hours
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

-- Alert details view
CREATE OR REPLACE VIEW alert_details AS
SELECT 
    a.id,
    a.alert_code,
    a.alert_type,
    a.severity,
    a.status,
    a.title,
    a.message,
    a.product_id,
    p.sku as product_sku,
    p.name as product_name,
    a.location_id,
    l.code as location_code,
    l.name as location_name,
    a.current_value,
    a.threshold_value,
    a.variance_percentage,
    a.requires_action,
    a.escalation_level,
    a.acknowledged_by,
    u1.first_name || ' ' || u1.last_name as acknowledged_by_name,
    a.acknowledged_at,
    a.resolved_by,
    u2.first_name || ' ' || u2.last_name as resolved_by_name,
    a.resolved_at,
    a.created_at,
    EXTRACT(HOUR FROM CURRENT_TIMESTAMP - a.created_at) as age_hours,
    CASE 
        WHEN a.status = 'active' AND a.created_at < CURRENT_TIMESTAMP - INTERVAL '24 hours' THEN true
        ELSE false
    END as is_overdue
FROM alerts a
LEFT JOIN products p ON a.product_id = p.id
LEFT JOIN locations l ON a.location_id = l.id
LEFT JOIN users u1 ON a.acknowledged_by = u1.id
LEFT JOIN users u2 ON a.resolved_by = u2.id;

-- ==================== FINANCIAL VIEWS ====================

-- Inventory valuation view
CREATE OR REPLACE VIEW inventory_valuation AS
SELECT 
    l.id as location_id,
    l.code as location_code,
    l.name as location_name,
    c.id as category_id,
    c.name as category_name,
    COUNT(DISTINCT p.id) as product_count,
    SUM(sl.quantity) as total_quantity,
    SUM(sl.total_value) as total_value,
    AVG(sl.average_cost) as avg_cost_per_unit,
    SUM(CASE WHEN sl.quantity > 0 THEN sl.total_value END) as positive_stock_value,
    SUM(CASE WHEN sl.quantity < 0 THEN sl.total_value END) as negative_stock_value,
    COUNT(CASE WHEN sl.quantity <= 0 THEN 1 END) as out_of_stock_count,
    COUNT(CASE WHEN sl.quantity <= COALESCE(sl.min_stock, 0) THEN 1 END) as low_stock_count
FROM locations l
CROSS JOIN categories c
LEFT JOIN stock_levels sl ON l.id = sl.location_id
LEFT JOIN products p ON sl.product_id = p.id AND p.category_id = c.id
WHERE l.is_active = true AND c.is_active = true
GROUP BY l.id, l.code, l.name, c.id, c.name
HAVING COUNT(DISTINCT p.id) > 0
ORDER BY l.name, c.name;

-- Cost analysis view
CREATE OR REPLACE VIEW cost_analysis AS
SELECT 
    p.id as product_id,
    p.sku,
    p.name as product_name,
    p.unit_price,
    p.cost_price,
    
    -- Current stock costs
    SUM(sl.quantity * sl.average_cost) as current_stock_value,
    AVG(sl.average_cost) as weighted_avg_cost,
    
    -- Recent cost trends (last 30 days)
    AVG(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '30 days' AND im.unit_cost IS NOT NULL 
             THEN im.unit_cost END) as recent_avg_cost,
    MIN(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '30 days' AND im.unit_cost IS NOT NULL 
             THEN im.unit_cost END) as recent_min_cost,
    MAX(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '30 days' AND im.unit_cost IS NOT NULL 
             THEN im.unit_cost END) as recent_max_cost,
    
    -- Cost variance
    CASE 
        WHEN p.cost_price > 0 AND AVG(sl.average_cost) > 0 THEN 
            ((AVG(sl.average_cost) - p.cost_price) / p.cost_price) * 100
        ELSE 0
    END as cost_variance_percentage,
    
    -- Profitability
    CASE 
        WHEN AVG(sl.average_cost) > 0 THEN 
            ((p.unit_price - AVG(sl.average_cost)) / AVG(sl.average_cost)) * 100
        ELSE 0
    END as current_margin_percentage
    
FROM products p
LEFT JOIN stock_levels sl ON p.id = sl.product_id
LEFT JOIN inventory_movements im ON p.id = im.product_id 
    AND im.movement_type = 'in' 
    AND im.movement_status = 'completed'
WHERE p.is_active = true AND p.is_trackable = true
GROUP BY p.id, p.sku, p.name, p.unit_price, p.cost_price;

-- ==================== OPERATIONAL VIEWS ====================

-- Location summary view
CREATE OR REPLACE VIEW location_summary AS
SELECT 
    l.id as location_id,
    l.code as location_code,
    l.name as location_name,
    l.type as location_type,
    l.city,
    l.is_active,
    l.storage_capacity,
    l.storage_unit,
    m.first_name || ' ' || m.last_name as manager_name,
    
    -- Stock metrics
    COUNT(DISTINCT sl.product_id) as unique_products,
    SUM(sl.quantity) as total_quantity,
    SUM(sl.total_value) as total_value,
    COUNT(CASE WHEN sl.quantity <= 0 THEN 1 END) as out_of_stock_products,
    COUNT(CASE WHEN sl.quantity <= COALESCE(sl.min_stock, 0) THEN 1 END) as low_stock_products,
    
    -- Activity metrics (last 30 days)
    COUNT(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_movements,
    SUM(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '30 days' AND im.movement_type = 'in' 
             THEN im.quantity END) as recent_inbound,
    SUM(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '30 days' AND im.movement_type = 'out' 
             THEN ABS(im.quantity) END) as recent_outbound,
    
    -- Capacity utilization (if storage capacity is defined)
    CASE 
        WHEN l.storage_capacity > 0 THEN 
            (SUM(sl.quantity) / l.storage_capacity) * 100
        ELSE NULL
    END as capacity_utilization_percentage
    
FROM locations l
LEFT JOIN users m ON l.manager_id = m.id
LEFT JOIN stock_levels sl ON l.id = sl.location_id
LEFT JOIN inventory_movements im ON l.id = im.location_id AND im.movement_status = 'completed'
WHERE l.is_active = true
GROUP BY l.id, l.code, l.name, l.type, l.city, l.is_active, 
         l.storage_capacity, l.storage_unit, m.first_name, m.last_name;

-- User activity view
CREATE OR REPLACE VIEW user_activity AS
SELECT 
    u.id as user_id,
    u.email,
    u.first_name || ' ' || u.last_name as full_name,
    u.role,
    u.is_active,
    u.last_login_at,
    
    -- Movement activity (last 30 days)
    COUNT(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as movements_30d,
    COUNT(CASE WHEN im.processed_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as movements_7d,
    
    -- Alert activity (last 30 days)
    COUNT(CASE WHEN a.acknowledged_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as alerts_acknowledged_30d,
    COUNT(CASE WHEN a.resolved_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as alerts_resolved_30d,
    
    -- Last activity
    GREATEST(u.last_login_at, MAX(im.processed_at), MAX(a.acknowledged_at), MAX(a.resolved_at)) as last_activity,
    
    -- Activity level
    CASE 
        WHEN GREATEST(u.last_login_at, MAX(im.processed_at), MAX(a.acknowledged_at), MAX(a.resolved_at)) >= CURRENT_DATE - INTERVAL '7 days' THEN 'high'
        WHEN GREATEST(u.last_login_at, MAX(im.processed_at), MAX(a.acknowledged_at), MAX(a.resolved_at)) >= CURRENT_DATE - INTERVAL '30 days' THEN 'medium'
        WHEN GREATEST(u.last_login_at, MAX(im.processed_at), MAX(a.acknowledged_at), MAX(a.resolved_at)) >= CURRENT_DATE - INTERVAL '90 days' THEN 'low'
        ELSE 'inactive'
    END as activity_level
    
FROM users u
LEFT JOIN inventory_movements im ON u.id = im.processed_by
LEFT JOIN alerts a ON u.id = a.acknowledged_by OR u.id = a.resolved_by
WHERE u.is_active = true
GROUP BY u.id, u.email, u.first_name, u.last_name, u.role, u.is_active, u.last_login_at;

-- ==================== COMMENTS ====================

COMMENT ON VIEW stock_alerts IS 'Shows products with stock alerts (low, out of stock, overstock, reorder needed)';
COMMENT ON VIEW current_stock_summary IS 'Summary of current stock levels by product across all locations';
COMMENT ON VIEW movement_summary IS 'Daily summary of inventory movements by type and location';
COMMENT ON VIEW product_performance IS 'Product performance metrics including sales, velocity, and profitability';
COMMENT ON VIEW supplier_performance IS 'Supplier performance metrics and activity levels';
COMMENT ON VIEW active_alerts_summary IS 'Summary of active alerts by type and severity';
COMMENT ON VIEW alert_details IS 'Detailed view of alerts with related product and location information';
COMMENT ON VIEW inventory_valuation IS 'Inventory valuation by location and category';
COMMENT ON VIEW cost_analysis IS 'Cost analysis and variance tracking for products';
COMMENT ON VIEW location_summary IS 'Summary of location metrics including stock and activity';
COMMENT ON VIEW user_activity IS 'User activity levels and engagement metrics';

-- Views created successfully
SELECT 'Database views created successfully' as status;
SELECT COUNT(*) || ' views created' as summary 
FROM information_schema.views 
WHERE table_schema = 'public';