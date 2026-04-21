-- ============================================================================
-- Sample Schema for Databricks Lakebase Data API
-- ============================================================================
-- This is a sample schema demonstrating tables suitable for the Data API.
-- Run this SQL in the Lakebase SQL Editor to create example tables.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Categories Table
-- ---------------------------------------------------------------------------
CREATE TABLE categories (
    category_id   SERIAL      PRIMARY KEY,
    name          TEXT        NOT NULL UNIQUE,
    description   TEXT,
    created_at    TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- Products Table
-- ---------------------------------------------------------------------------
CREATE TABLE products (
    product_id    SERIAL         PRIMARY KEY,
    name          TEXT           NOT NULL,
    category_id   INTEGER        REFERENCES categories(category_id),
    price         NUMERIC(10,2)  NOT NULL,
    in_stock      BOOLEAN        DEFAULT TRUE,
    created_at    TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON products(category_id);

-- ============================================================================
-- Sample Data
-- ============================================================================

-- Insert sample categories
INSERT INTO categories (name, description) VALUES
    ('Electronics', 'Computers, phones, and gadgets'),
    ('Furniture', 'Office and home furniture'),
    ('Accessories', 'Peripherals and add-ons');

-- Insert sample products
INSERT INTO products (name, category_id, price, in_stock) VALUES
    ('Laptop Pro', 1, 1299.99, TRUE),
    ('Wireless Mouse', 3, 29.99, TRUE),
    ('Standing Desk', 2, 599.00, TRUE),
    ('USB-C Hub', 3, 49.99, FALSE),
    ('Office Chair', 2, 349.50, TRUE),
    ('Monitor 27"', 1, 449.99, TRUE),
    ('Keyboard Mechanical', 3, 159.99, TRUE),
    ('Desk Lamp', 2, 89.99, TRUE);

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Check data
SELECT 
    p.product_id,
    p.name,
    c.name AS category,
    p.price,
    p.in_stock
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id
ORDER BY p.product_id;
