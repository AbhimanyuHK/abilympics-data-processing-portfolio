-- ============================================================================
-- 01_ddl_tables_constraints.sql
-- Vocational Portfolio — Data Management & Processing
-- Target: SQLite 3 (offline)
-- Purpose: 3NF procurement/inventory schema with enforceable integrity rules.
-- ============================================================================

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- ----------------------------------------------------------------------------
-- Master: suppliers
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_code    TEXT NOT NULL UNIQUE,
    supplier_name    TEXT NOT NULL,
    contact_name     TEXT NOT NULL,
    phone            TEXT NOT NULL,
    email            TEXT NOT NULL,
    city             TEXT NOT NULL,
    state            TEXT NOT NULL,
    supplier_status  TEXT NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT ck_suppliers_code_nonempty
        CHECK (length(trim(supplier_code)) > 0),
    CONSTRAINT ck_suppliers_name_nonempty
        CHECK (length(trim(supplier_name)) > 0),
    CONSTRAINT ck_suppliers_status
        CHECK (supplier_status IN ('ACTIVE', 'INACTIVE'))
);

-- ----------------------------------------------------------------------------
-- Master: categories
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    category_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    category_code    TEXT NOT NULL UNIQUE,
    category_name    TEXT NOT NULL,
    category_status  TEXT NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT ck_categories_code_nonempty
        CHECK (length(trim(category_code)) > 0),
    CONSTRAINT ck_categories_name_nonempty
        CHECK (length(trim(category_name)) > 0),
    CONSTRAINT ck_categories_status
        CHECK (category_status IN ('ACTIVE', 'INACTIVE'))
);

-- ----------------------------------------------------------------------------
-- Master: inventory_items
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inventory_items (
    item_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    item_code        TEXT NOT NULL UNIQUE,
    item_name        TEXT NOT NULL,
    category_id      INTEGER NOT NULL,
    unit_of_measure  TEXT NOT NULL,
    reorder_level    INTEGER NOT NULL DEFAULT 0,
    current_stock    INTEGER NOT NULL DEFAULT 0,
    item_status      TEXT NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_inventory_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT ck_inventory_code_nonempty
        CHECK (length(trim(item_code)) > 0),
    CONSTRAINT ck_inventory_name_nonempty
        CHECK (length(trim(item_name)) > 0),
    CONSTRAINT ck_inventory_uom_nonempty
        CHECK (length(trim(unit_of_measure)) > 0),
    CONSTRAINT ck_inventory_reorder_nonnegative
        CHECK (reorder_level >= 0),
    CONSTRAINT ck_inventory_stock_nonnegative
        CHECK (current_stock >= 0),
    CONSTRAINT ck_inventory_status
        CHECK (item_status IN ('ACTIVE', 'INACTIVE', 'DISCONTINUED'))
);

-- ----------------------------------------------------------------------------
-- Transaction header: purchase_orders
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS purchase_orders (
    purchase_order_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    order_number       TEXT NOT NULL UNIQUE,
    supplier_id       INTEGER NOT NULL,
    order_date        TEXT NOT NULL,
    delivery_date     TEXT,
    order_status      TEXT NOT NULL DEFAULT 'PENDING',
    CONSTRAINT fk_purchase_orders_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT ck_purchase_orders_number_nonempty
        CHECK (length(trim(order_number)) > 0),
    CONSTRAINT ck_purchase_orders_order_date
        CHECK (
            order_date GLOB '____-__-__'
            AND date(order_date) IS NOT NULL
        ),
    CONSTRAINT ck_purchase_orders_delivery_date
        CHECK (
            delivery_date IS NULL
            OR (
                delivery_date GLOB '____-__-__'
                AND date(delivery_date) IS NOT NULL
                AND delivery_date >= order_date
            )
        ),
    CONSTRAINT ck_purchase_orders_status
        CHECK (order_status IN ('PENDING', 'APPROVED', 'RECEIVED', 'CANCELLED'))
);

-- ----------------------------------------------------------------------------
-- Transaction detail: order_lines
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_lines (
    order_line_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    purchase_order_id  INTEGER NOT NULL,
    item_id            INTEGER NOT NULL,
    quantity           INTEGER NOT NULL,
    unit_price         REAL NOT NULL,
    CONSTRAINT fk_order_lines_purchase_order
        FOREIGN KEY (purchase_order_id)
        REFERENCES purchase_orders(purchase_order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_lines_item
        FOREIGN KEY (item_id)
        REFERENCES inventory_items(item_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT uq_order_lines_order_item
        UNIQUE (purchase_order_id, item_id),
    CONSTRAINT ck_order_lines_quantity_positive
        CHECK (quantity > 0),
    CONSTRAINT ck_order_lines_unit_price_nonnegative
        CHECK (unit_price >= 0)
);

-- ----------------------------------------------------------------------------
-- Supporting indexes.
-- Primary keys and UNIQUE constraints already create indexes where applicable.
-- These indexes target common FK joins and analytical access paths.
-- ----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_inventory_items_category_id
    ON inventory_items(category_id);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier_id
    ON purchase_orders(supplier_id);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_order_date
    ON purchase_orders(order_date);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_status
    ON purchase_orders(order_status);

CREATE INDEX IF NOT EXISTS idx_order_lines_purchase_order_id
    ON order_lines(purchase_order_id);

CREATE INDEX IF NOT EXISTS idx_order_lines_item_id
    ON order_lines(item_id);

COMMIT;

-- ============================================================================
-- Integrity notes
-- ============================================================================
-- 1. Foreign keys are explicitly enabled for this SQLite connection.
-- 2. Supplier/category/item/order business codes are unique.
-- 3. Transactional rows cannot reference missing master records.
-- 4. Order lines are deleted automatically with their purchase-order header.
-- 5. Supplier, category, and inventory master rows cannot be deleted while
--    referenced by dependent records.
-- 6. Quantity and unit price are constrained to valid economic values.
-- 7. Delivery dates cannot precede order dates.
-- 8. Controlled status vocabularies prevent free-form lifecycle values.
-- 9. (purchase_order_id, item_id) prevents duplicate item lines per PO.
