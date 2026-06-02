-- Supabase PostgreSQL Schema for ERP System

-- 1. Roles & Users (using Supabase Auth custom table extension)
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    permissions TEXT NOT NULL
);

CREATE TABLE app_users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL UNIQUE,
    role_id INTEGER NOT NULL REFERENCES roles(id),
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- 2. HR (Employees)
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    position TEXT,
    salary NUMERIC NOT NULL,
    hire_date DATE,
    user_id UUID REFERENCES app_users(id)
);

-- 3. CRM & Suppliers
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    balance NUMERIC NOT NULL DEFAULT 0.0
);

CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    balance NUMERIC NOT NULL DEFAULT 0.0
);

-- 4. Inventory
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE warehouses (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES categories(id),
    name TEXT NOT NULL,
    barcode TEXT UNIQUE,
    purchase_price NUMERIC NOT NULL,
    sale_price NUMERIC NOT NULL,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    min_stock_alert INTEGER NOT NULL DEFAULT 5
);

CREATE TABLE inventory_transactions (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id),
    warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
    transaction_type TEXT NOT NULL, -- IN / OUT
    quantity INTEGER NOT NULL,
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    notes TEXT
);

-- 5. Sales & Purchases
CREATE TABLE sales_invoices (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    user_id UUID NOT NULL REFERENCES app_users(id),
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    total_amount NUMERIC NOT NULL,
    paid_amount NUMERIC NOT NULL,
    status TEXT NOT NULL -- PAID / PARTIAL / UNPAID
);

CREATE TABLE sales_items (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER NOT NULL REFERENCES sales_invoices(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC NOT NULL,
    total NUMERIC NOT NULL
);

CREATE TABLE purchase_invoices (
    id SERIAL PRIMARY KEY,
    supplier_id INTEGER NOT NULL REFERENCES suppliers(id),
    user_id UUID NOT NULL REFERENCES app_users(id),
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    total_amount NUMERIC NOT NULL,
    paid_amount NUMERIC NOT NULL,
    status TEXT NOT NULL
);

CREATE TABLE purchase_items (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER NOT NULL REFERENCES purchase_invoices(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC NOT NULL,
    total NUMERIC NOT NULL
);

-- 6. Accounting
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    account_name TEXT NOT NULL,
    account_type TEXT NOT NULL, -- ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
    balance NUMERIC NOT NULL DEFAULT 0.0
);

CREATE TABLE journal_entries (
    id SERIAL PRIMARY KEY,
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    description TEXT NOT NULL,
    total_debit NUMERIC NOT NULL,
    total_credit NUMERIC NOT NULL
);

-- Default Data for Roles
INSERT INTO roles (name, permissions) VALUES ('Admin', 'ALL');
INSERT INTO roles (name, permissions) VALUES ('Accountant', 'accounting,sales');

-- Enable Row Level Security (Optional for extra security)
-- ALTER TABLE products ENABLE ROW LEVEL SECURITY;
