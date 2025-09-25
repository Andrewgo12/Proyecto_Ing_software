-- Schema: database-schema.sql
-- Description: Complete database schema definition for Sistema de Inventario PYMES
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- ==================== DATABASE INFORMATION ====================

-- Database: inventario_pymes
-- Version: PostgreSQL 14+
-- Encoding: UTF8
-- Collation: es_CO.UTF-8
-- Character Type: es_CO.UTF-8

-- ==================== EXTENSIONS ====================

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";           -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";            -- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";             -- Trigram matching for search
CREATE EXTENSION IF NOT EXISTS "unaccent";            -- Remove accents for search
CREATE EXTENSION IF NOT EXISTS "btree_gin";           -- GIN indexes for btree operations
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";  -- Query statistics

-- ==================== CUSTOM TYPES ====================

-- Location types
CREATE TYPE location_type AS ENUM ('warehouse', 'store', 'transit', 'supplier', 'customer', 'virtual');

-- Movement types
CREATE TYPE movement_type AS ENUM (
    'in', 'out', 'transfer', 'adjustment', 'reservation', 
    'allocation', 'return', 'damage', 'expired', 'lost', 'found'
);

-- Movement status
CREATE TYPE movement_status AS ENUM ('pending', 'processing', 'completed', 'cancelled', 'failed');

-- Alert types
CREATE TYPE alert_type AS ENUM (
    'low_stock', 'out_of_stock', 'overstock', 'expiry_warning', 'expired',
    'slow_moving', 'fast_moving', 'negative_stock', 'cycle_count_due',
    'price_change', 'cost_variance', 'system_error'
);

-- Alert severity
CREATE TYPE alert_severity AS ENUM ('low', 'medium', 'high', 'critical');

-- Alert status
CREATE TYPE alert_status AS ENUM ('active', 'acknowledged', 'resolved', 'dismissed', 'expired');

-- Supplier status
CREATE TYPE supplier_status AS ENUM ('active', 'inactive', 'suspended', 'blacklisted', 'pending_approval');

-- Supplier types
CREATE TYPE supplier_type AS ENUM ('manufacturer', 'distributor', 'wholesaler', 'retailer', 'service_provider', 'dropshipper');

-- ==================== CORE TABLES ====================

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'manager', 'warehouse', 'sales', 'viewer')),
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMP,
    last_login_at TIMESTAMP,
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Categories table (hierarchical)
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    parent_id UUID REFERENCES categories(id),
    level INTEGER NOT NULL DEFAULT 0,
    path VARCHAR(500),
    sort_order INTEGER DEFAULT 0,
    icon VARCHAR(50),
    color VARCHAR(7),
    is_active BOOLEAN DEFAULT true,
    meta_title VARCHAR(255),
    meta_description TEXT,
    custom_fields JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Locations table
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
    operating_hours JSONB,
    timezone VARCHAR(50) DEFAULT 'America/Bogota',
    cost_center VARCHAR(50),
    gl_account VARCHAR(50),
    custom_fields JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Suppliers table
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_code VARCHAR(20) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    trade_name VARCHAR(255),
    tax_id VARCHAR(50) UNIQUE NOT NULL,
    supplier_type supplier_type NOT NULL DEFAULT 'distributor',
    status supplier_status NOT NULL DEFAULT 'active',
    primary_contact_name VARCHAR(100),
    primary_contact_title VARCHAR(100),
    primary_contact_email VARCHAR(255),
    primary_contact_phone VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Colombia',
    website VARCHAR(255),
    phone VARCHAR(20),
    fax VARCHAR(20),
    email VARCHAR(255),
    industry VARCHAR(100),
    business_registration_number VARCHAR(50),
    business_registration_date DATE,
    established_year INTEGER,
    employee_count INTEGER,
    annual_revenue DECIMAL(15,2),
    currency_code VARCHAR(3) DEFAULT 'COP',
    payment_terms VARCHAR(100),
    payment_method VARCHAR(50),
    credit_limit DECIMAL(12,2),
    credit_days INTEGER DEFAULT 30,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    tax_exempt BOOLEAN DEFAULT false,
    lead_time_days INTEGER DEFAULT 7,
    minimum_order_amount DECIMAL(12,2),
    delivery_performance_score DECIMAL(3,2),
    quality_rating DECIMAL(3,2),
    price_competitiveness_score DECIMAL(3,2),
    overall_rating DECIMAL(3,2),
    certifications JSONB,
    compliance_documents JSONB,
    insurance_info JSONB,
    bank_name VARCHAR(100),
    bank_account_number VARCHAR(50),
    bank_routing_number VARCHAR(20),
    swift_code VARCHAR(11),
    contract_start_date DATE,
    contract_end_date DATE,
    contract_terms TEXT,
    preferred_supplier BOOLEAN DEFAULT false,
    exclusive_supplier BOOLEAN DEFAULT false,
    internal_notes TEXT,
    public_notes TEXT,
    tags JSONB,
    custom_fields JSONB,
    last_order_date DATE,
    last_payment_date DATE,
    total_orders_count INTEGER DEFAULT 0,
    total_orders_value DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Supplier contacts table
CREATE TABLE supplier_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    contact_type VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    title VARCHAR(100),
    department VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    mobile VARCHAR(20),
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
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
    dimensions JSONB,
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
    images JSONB,
    tags JSONB,
    custom_fields JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Stock levels table
CREATE TABLE stock_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    quantity DECIMAL(12,3) NOT NULL DEFAULT 0,
    reserved_quantity DECIMAL(12,3) NOT NULL DEFAULT 0,
    available_quantity DECIMAL(12,3) GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
    allocated_quantity DECIMAL(12,3) NOT NULL DEFAULT 0,
    on_order_quantity DECIMAL(12,3) NOT NULL DEFAULT 0,
    min_stock DECIMAL(12,3),
    max_stock DECIMAL(12,3),
    reorder_point DECIMAL(12,3),
    reorder_quantity DECIMAL(12,3),
    safety_stock DECIMAL(12,3) DEFAULT 0,
    abc_classification CHAR(1) CHECK (abc_classification IN ('A', 'B', 'C')),
    velocity_classification VARCHAR(10) CHECK (velocity_classification IN ('fast', 'medium', 'slow', 'dead')),
    last_movement_date TIMESTAMP,
    last_count_date TIMESTAMP,
    last_count_quantity DECIMAL(12,3),
    last_count_variance DECIMAL(12,3),
    last_count_user_id UUID REFERENCES users(id),
    cycle_count_due_date DATE,
    lot_tracking BOOLEAN DEFAULT false,
    serial_tracking BOOLEAN DEFAULT false,
    expiry_tracking BOOLEAN DEFAULT false,
    cost_method VARCHAR(10) DEFAULT 'FIFO' CHECK (cost_method IN ('FIFO', 'LIFO', 'AVERAGE', 'SPECIFIC')),
    average_cost DECIMAL(12,4),
    last_cost DECIMAL(12,4),
    total_value DECIMAL(15,2) GENERATED ALWAYS AS (quantity * COALESCE(average_cost, 0)) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    UNIQUE(product_id, location_id)
);

-- Inventory movements table
CREATE TABLE inventory_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movement_number VARCHAR(50) UNIQUE NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id),
    location_id UUID NOT NULL REFERENCES locations(id),
    movement_type movement_type NOT NULL,
    movement_status movement_status DEFAULT 'completed',
    quantity DECIMAL(12,3) NOT NULL,
    unit_cost DECIMAL(12,4),
    total_cost DECIMAL(15,2) GENERATED ALWAYS AS (ABS(quantity) * COALESCE(unit_cost, 0)) STORED,
    reference_type VARCHAR(50),
    reference_id UUID,
    reference_number VARCHAR(50),
    batch_number VARCHAR(50),
    lot_number VARCHAR(50),
    serial_number VARCHAR(100),
    expiry_date DATE,
    manufacture_date DATE,
    destination_location_id UUID REFERENCES locations(id),
    reason_code VARCHAR(20),
    notes TEXT,
    external_document_number VARCHAR(50),
    external_document_date DATE,
    supplier_id UUID REFERENCES suppliers(id),
    customer_id UUID,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_by UUID NOT NULL REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    reversed_by UUID REFERENCES users(id),
    reversed_at TIMESTAMP,
    reversal_reason TEXT,
    parent_movement_id UUID REFERENCES inventory_movements(id),
    tags JSONB,
    custom_fields JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Alerts table
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

-- ==================== AUDIT AND SYSTEM TABLES ====================

-- Audit log table
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(50) NOT NULL,
    record_id UUID NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    user_id UUID REFERENCES users(id),
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    recipient_user_id UUID REFERENCES users(id),
    recipient_role VARCHAR(20),
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    is_sent BOOLEAN DEFAULT false,
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== CONSTRAINTS ====================

-- Users constraints
ALTER TABLE users ADD CONSTRAINT chk_users_role 
    CHECK (role IN ('admin', 'manager', 'warehouse', 'sales', 'viewer'));

-- Categories constraints
ALTER TABLE categories ADD CONSTRAINT chk_categories_level 
    CHECK (level >= 0 AND level <= 5);
ALTER TABLE categories ADD CONSTRAINT chk_categories_color 
    CHECK (color IS NULL OR color ~ '^#[0-9A-Fa-f]{6}$');
ALTER TABLE categories ADD CONSTRAINT chk_categories_no_self_reference 
    CHECK (id != parent_id);

-- Locations constraints
ALTER TABLE locations ADD CONSTRAINT chk_locations_storage_capacity 
    CHECK (storage_capacity IS NULL OR storage_capacity > 0);
ALTER TABLE locations ADD CONSTRAINT chk_locations_email 
    CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
ALTER TABLE locations ADD CONSTRAINT chk_locations_no_self_reference 
    CHECK (id != parent_location_id);

-- Products constraints
ALTER TABLE products ADD CONSTRAINT chk_products_min_max_stock 
    CHECK (max_stock_level IS NULL OR min_stock_level <= max_stock_level);
ALTER TABLE products ADD CONSTRAINT chk_products_reorder_point 
    CHECK (reorder_point IS NULL OR reorder_point >= min_stock_level);

-- Suppliers constraints
ALTER TABLE suppliers ADD CONSTRAINT chk_suppliers_credit_limit_positive 
    CHECK (credit_limit IS NULL OR credit_limit >= 0);
ALTER TABLE suppliers ADD CONSTRAINT chk_suppliers_discount_percentage 
    CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- Inventory movements constraints
ALTER TABLE inventory_movements ADD CONSTRAINT chk_inventory_movements_quantity_not_zero 
    CHECK (quantity != 0);

-- Alerts constraints
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_escalation_level 
    CHECK (escalation_level >= 0 AND escalation_level <= 5);

-- ==================== SCHEMA SUMMARY ====================

-- Total tables: 11 main tables + 2 system tables = 13 tables
-- Total custom types: 8 enums
-- Total constraints: 15+ check constraints
-- Total indexes: 50+ indexes (created in separate migration)
-- Total triggers: 10+ triggers (created in separate migration)

SELECT 'Database schema created successfully' as status;
SELECT 
    'Tables: ' || COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';