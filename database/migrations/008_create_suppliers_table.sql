-- Migration: 008_create_suppliers_table.sql
-- Description: Create suppliers table for vendor management
-- Author: Sistema de Inventario PYMES Team
-- Date: 2024-01-15

-- Create supplier status enum
CREATE TYPE supplier_status AS ENUM ('active', 'inactive', 'suspended', 'blacklisted', 'pending_approval');

-- Create supplier types enum
CREATE TYPE supplier_type AS ENUM ('manufacturer', 'distributor', 'wholesaler', 'retailer', 'service_provider', 'dropshipper');

-- Create suppliers table
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_code VARCHAR(20) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    trade_name VARCHAR(255),
    tax_id VARCHAR(50) UNIQUE NOT NULL,
    supplier_type supplier_type NOT NULL DEFAULT 'distributor',
    status supplier_status NOT NULL DEFAULT 'active',
    
    -- Contact Information
    primary_contact_name VARCHAR(100),
    primary_contact_title VARCHAR(100),
    primary_contact_email VARCHAR(255),
    primary_contact_phone VARCHAR(20),
    
    -- Address Information
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Colombia',
    
    -- Additional Contact Methods
    website VARCHAR(255),
    phone VARCHAR(20),
    fax VARCHAR(20),
    email VARCHAR(255),
    
    -- Business Information
    industry VARCHAR(100),
    business_registration_number VARCHAR(50),
    business_registration_date DATE,
    established_year INTEGER,
    employee_count INTEGER,
    annual_revenue DECIMAL(15,2),
    
    -- Financial Information
    currency_code VARCHAR(3) DEFAULT 'COP',
    payment_terms VARCHAR(100),
    payment_method VARCHAR(50),
    credit_limit DECIMAL(12,2),
    credit_days INTEGER DEFAULT 30,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    tax_exempt BOOLEAN DEFAULT false,
    
    -- Performance Metrics
    lead_time_days INTEGER DEFAULT 7,
    minimum_order_amount DECIMAL(12,2),
    delivery_performance_score DECIMAL(3,2), -- 0.00 to 5.00
    quality_rating DECIMAL(3,2), -- 0.00 to 5.00
    price_competitiveness_score DECIMAL(3,2), -- 0.00 to 5.00
    overall_rating DECIMAL(3,2), -- 0.00 to 5.00
    
    -- Certifications and Compliance
    certifications JSONB, -- Array of certification objects
    compliance_documents JSONB, -- Array of document objects
    insurance_info JSONB, -- Insurance information
    
    -- Banking Information (encrypted in production)
    bank_name VARCHAR(100),
    bank_account_number VARCHAR(50),
    bank_routing_number VARCHAR(20),
    swift_code VARCHAR(11),
    
    -- Contract Information
    contract_start_date DATE,
    contract_end_date DATE,
    contract_terms TEXT,
    preferred_supplier BOOLEAN DEFAULT false,
    exclusive_supplier BOOLEAN DEFAULT false,
    
    -- Internal Notes and Management
    internal_notes TEXT,
    public_notes TEXT,
    tags JSONB, -- Array of tags
    custom_fields JSONB,
    
    -- Audit Fields
    last_order_date DATE,
    last_payment_date DATE,
    total_orders_count INTEGER DEFAULT 0,
    total_orders_value DECIMAL(15,2) DEFAULT 0,
    
    -- System Fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create indexes for performance
CREATE INDEX idx_suppliers_supplier_code ON suppliers(supplier_code);
CREATE INDEX idx_suppliers_company_name ON suppliers(company_name);
CREATE INDEX idx_suppliers_tax_id ON suppliers(tax_id);
CREATE INDEX idx_suppliers_supplier_type ON suppliers(supplier_type);
CREATE INDEX idx_suppliers_status ON suppliers(status);
CREATE INDEX idx_suppliers_primary_contact_email ON suppliers(primary_contact_email);
CREATE INDEX idx_suppliers_city ON suppliers(city);
CREATE INDEX idx_suppliers_country ON suppliers(country);
CREATE INDEX idx_suppliers_preferred ON suppliers(preferred_supplier);
CREATE INDEX idx_suppliers_created_at ON suppliers(created_at);
CREATE INDEX idx_suppliers_last_order_date ON suppliers(last_order_date);

-- Full-text search index
CREATE INDEX idx_suppliers_search ON suppliers USING gin(
    to_tsvector('spanish', 
        company_name || ' ' || 
        COALESCE(trade_name, '') || ' ' || 
        COALESCE(primary_contact_name, '') || ' ' ||
        COALESCE(industry, '')
    )
);

-- JSONB indexes
CREATE INDEX idx_suppliers_tags ON suppliers USING gin(tags);
CREATE INDEX idx_suppliers_certifications ON suppliers USING gin(certifications);

-- Create trigger for updated_at
CREATE TRIGGER update_suppliers_updated_at 
    BEFORE UPDATE ON suppliers 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to generate supplier codes
CREATE OR REPLACE FUNCTION generate_supplier_code()
RETURNS TRIGGER AS $$
DECLARE
    type_prefix VARCHAR(5);
    sequence_num INTEGER;
    new_code VARCHAR(20);
BEGIN
    -- Set prefix based on supplier type
    type_prefix := CASE NEW.supplier_type
        WHEN 'manufacturer' THEN 'MFG'
        WHEN 'distributor' THEN 'DIST'
        WHEN 'wholesaler' THEN 'WHL'
        WHEN 'retailer' THEN 'RTL'
        WHEN 'service_provider' THEN 'SVC'
        WHEN 'dropshipper' THEN 'DROP'
        ELSE 'SUP'
    END;
    
    -- Get next sequence number
    SELECT COALESCE(MAX(CAST(SUBSTRING(supplier_code FROM LENGTH(type_prefix) + 1) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM suppliers
    WHERE supplier_code LIKE type_prefix || '%';
    
    -- Generate new supplier code
    new_code := type_prefix || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.supplier_code := new_code;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for supplier code generation
CREATE TRIGGER generate_supplier_code_trigger
    BEFORE INSERT ON suppliers
    FOR EACH ROW
    WHEN (NEW.supplier_code IS NULL)
    EXECUTE FUNCTION generate_supplier_code();

-- Function to validate supplier data
CREATE OR REPLACE FUNCTION validate_supplier_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate email format
    IF NEW.primary_contact_email IS NOT NULL AND NEW.primary_contact_email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Invalid primary contact email format';
    END IF;
    
    IF NEW.email IS NOT NULL AND NEW.email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Invalid email format';
    END IF;
    
    -- Validate website URL format
    IF NEW.website IS NOT NULL AND NEW.website !~* '^https?://[^\s/$.?#].[^\s]*$' THEN
        RAISE EXCEPTION 'Invalid website URL format';
    END IF;
    
    -- Validate rating ranges
    IF NEW.delivery_performance_score IS NOT NULL AND (NEW.delivery_performance_score < 0 OR NEW.delivery_performance_score > 5) THEN
        RAISE EXCEPTION 'Delivery performance score must be between 0 and 5';
    END IF;
    
    IF NEW.quality_rating IS NOT NULL AND (NEW.quality_rating < 0 OR NEW.quality_rating > 5) THEN
        RAISE EXCEPTION 'Quality rating must be between 0 and 5';
    END IF;
    
    IF NEW.price_competitiveness_score IS NOT NULL AND (NEW.price_competitiveness_score < 0 OR NEW.price_competitiveness_score > 5) THEN
        RAISE EXCEPTION 'Price competitiveness score must be between 0 and 5';
    END IF;
    
    IF NEW.overall_rating IS NOT NULL AND (NEW.overall_rating < 0 OR NEW.overall_rating > 5) THEN
        RAISE EXCEPTION 'Overall rating must be between 0 and 5';
    END IF;
    
    -- Validate contract dates
    IF NEW.contract_start_date IS NOT NULL AND NEW.contract_end_date IS NOT NULL 
       AND NEW.contract_start_date > NEW.contract_end_date THEN
        RAISE EXCEPTION 'Contract start date cannot be after end date';
    END IF;
    
    -- Validate established year
    IF NEW.established_year IS NOT NULL AND (NEW.established_year < 1800 OR NEW.established_year > EXTRACT(YEAR FROM CURRENT_DATE)) THEN
        RAISE EXCEPTION 'Invalid established year';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for supplier validation
CREATE TRIGGER validate_supplier_data_trigger
    BEFORE INSERT OR UPDATE ON suppliers
    FOR EACH ROW
    EXECUTE FUNCTION validate_supplier_data();

-- Function to calculate overall rating
CREATE OR REPLACE FUNCTION calculate_supplier_overall_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate overall rating as average of available metrics
    IF NEW.delivery_performance_score IS NOT NULL OR NEW.quality_rating IS NOT NULL OR NEW.price_competitiveness_score IS NOT NULL THEN
        NEW.overall_rating := (
            COALESCE(NEW.delivery_performance_score, 0) + 
            COALESCE(NEW.quality_rating, 0) + 
            COALESCE(NEW.price_competitiveness_score, 0)
        ) / (
            CASE WHEN NEW.delivery_performance_score IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN NEW.quality_rating IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN NEW.price_competitiveness_score IS NOT NULL THEN 1 ELSE 0 END
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for overall rating calculation
CREATE TRIGGER calculate_supplier_overall_rating_trigger
    BEFORE INSERT OR UPDATE ON suppliers
    FOR EACH ROW
    EXECUTE FUNCTION calculate_supplier_overall_rating();

-- Add constraints
ALTER TABLE suppliers ADD CONSTRAINT chk_suppliers_credit_limit_positive 
    CHECK (credit_limit IS NULL OR credit_limit >= 0);

ALTER TABLE suppliers ADD CONSTRAINT chk_suppliers_credit_days_positive 
    CHECK (credit_days IS NULL OR credit_days >= 0);

ALTER TABLE suppliers ADD CONSTRAINT chk_suppliers_discount_percentage 
    CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

ALTER TABLE suppliers ADD CONSTRAINT chk_suppliers_minimum_order_positive 
    CHECK (minimum_order_amount IS NULL OR minimum_order_amount >= 0);

ALTER TABLE suppliers ADD CONSTRAINT chk_suppliers_lead_time_positive 
    CHECK (lead_time_days IS NULL OR lead_time_days >= 0);

-- Add comments
COMMENT ON TABLE suppliers IS 'Supplier and vendor information for procurement management';
COMMENT ON COLUMN suppliers.supplier_code IS 'Unique supplier identifier (auto-generated)';
COMMENT ON COLUMN suppliers.tax_id IS 'Tax identification number (NIT in Colombia)';
COMMENT ON COLUMN suppliers.supplier_type IS 'Type of supplier business model';
COMMENT ON COLUMN suppliers.status IS 'Current supplier status';
COMMENT ON COLUMN suppliers.payment_terms IS 'Payment terms (e.g., Net 30, COD, etc.)';
COMMENT ON COLUMN suppliers.lead_time_days IS 'Average delivery lead time in days';
COMMENT ON COLUMN suppliers.delivery_performance_score IS 'On-time delivery performance (0-5)';
COMMENT ON COLUMN suppliers.quality_rating IS 'Product quality rating (0-5)';
COMMENT ON COLUMN suppliers.price_competitiveness_score IS 'Price competitiveness rating (0-5)';
COMMENT ON COLUMN suppliers.overall_rating IS 'Calculated overall supplier rating (0-5)';
COMMENT ON COLUMN suppliers.preferred_supplier IS 'Whether this is a preferred supplier';
COMMENT ON COLUMN suppliers.exclusive_supplier IS 'Whether this supplier has exclusive rights';

-- Create supplier contacts table for multiple contacts per supplier
CREATE TABLE supplier_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    contact_type VARCHAR(50) NOT NULL, -- 'primary', 'billing', 'technical', 'sales', etc.
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

-- Create indexes for supplier contacts
CREATE INDEX idx_supplier_contacts_supplier_id ON supplier_contacts(supplier_id);
CREATE INDEX idx_supplier_contacts_email ON supplier_contacts(email);
CREATE INDEX idx_supplier_contacts_is_primary ON supplier_contacts(is_primary);
CREATE INDEX idx_supplier_contacts_contact_type ON supplier_contacts(contact_type);

-- Create trigger for supplier contacts updated_at
CREATE TRIGGER update_supplier_contacts_updated_at 
    BEFORE UPDATE ON supplier_contacts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments for supplier contacts
COMMENT ON TABLE supplier_contacts IS 'Multiple contact persons for each supplier';
COMMENT ON COLUMN supplier_contacts.contact_type IS 'Type of contact (primary, billing, technical, sales)';
COMMENT ON COLUMN supplier_contacts.is_primary IS 'Whether this is the primary contact for the supplier';

-- Insert sample suppliers
INSERT INTO suppliers (
    company_name, tax_id, supplier_type, status, 
    primary_contact_name, primary_contact_email, primary_contact_phone,
    address_line1, city, country, phone, email,
    payment_terms, credit_days, lead_time_days,
    preferred_supplier
) VALUES 
(
    'Distribuidora Tecnológica S.A.S.', '900123456-1', 'distributor', 'active',
    'Carlos Rodríguez', 'carlos@distecnologica.com', '+57-1-234-5678',
    'Calle 100 #15-20', 'Bogotá', 'Colombia', '+57-1-234-5678', 'ventas@distecnologica.com',
    'Net 30', 30, 5, true
),
(
    'Suministros Industriales Ltda.', '800987654-2', 'wholesaler', 'active',
    'María González', 'maria@sumindustriales.com', '+57-1-987-6543',
    'Carrera 50 #80-45', 'Medellín', 'Colombia', '+57-4-987-6543', 'info@sumindustriales.com',
    'Net 15', 15, 3, false
),
(
    'Importadora Global S.A.', '700456789-3', 'manufacturer', 'active',
    'Juan Pérez', 'juan@importadoraglobal.com', '+57-1-456-7890',
    'Zona Franca Bogotá', 'Bogotá', 'Colombia', '+57-1-456-7890', 'compras@importadoraglobal.com',
    'COD', 0, 14, false
);

-- Add foreign key reference to inventory_movements (now that suppliers table exists)
ALTER TABLE inventory_movements 
ADD CONSTRAINT fk_inventory_movements_supplier 
FOREIGN KEY (supplier_id) REFERENCES suppliers(id);

-- Migration completed successfully
SELECT 'Migration 008_create_suppliers_table.sql completed successfully' as status;