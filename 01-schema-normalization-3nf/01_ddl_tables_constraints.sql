PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS categories (
    category_id INTEGER PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id INTEGER PRIMARY KEY,
    supplier_name VARCHAR(150) NOT NULL UNIQUE,
    contact_name VARCHAR(120),
    email VARCHAR(150),
    phone VARCHAR(30),
    address VARCHAR(255),
    active INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT ck_supplier_active CHECK (active IN (0, 1)),
    CONSTRAINT ck_supplier_email CHECK (
        email IS NULL OR (
            email LIKE '%@%.%'
            AND email NOT LIKE '% %'
        )
    )
);

CREATE TABLE IF NOT EXISTS inventory_items (
    item_id INTEGER PRIMARY KEY,
    item_code VARCHAR(30) NOT NULL UNIQUE,
    item_name VARCHAR(150) NOT NULL,
    category_id INTEGER NOT NULL,
    reorder_level INTEGER NOT NULL DEFAULT 0,
    current_stock INTEGER NOT NULL DEFAULT 0,
    standard_unit VARCHAR(20) NOT NULL DEFAULT 'EA',
    active INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT fk_item_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT ck_item_reorder CHECK (reorder_level >= 0),
    CONSTRAINT ck_item_stock CHECK (current_stock >= 0),
    CONSTRAINT ck_item_active CHECK (active IN (0, 1))
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    po_id INTEGER PRIMARY KEY,
    po_number VARCHAR(30) NOT NULL UNIQUE,
    supplier_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'INR',
    po_status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id) ON DELETE RESTRICT,
    CONSTRAINT ck_po_currency CHECK (length(currency_code) = 3),
    CONSTRAINT ck_po_status CHECK (
        po_status IN ('OPEN', 'PARTIALLY_DELIVERED', 'DELIVERED', 'CANCELLED')
    )
);

CREATE TABLE IF NOT EXISTS order_lines (
    order_line_id INTEGER PRIMARY KEY,
    po_id INTEGER NOT NULL,
    line_number INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    expected_delivery_date DATE NOT NULL,
    actual_delivery_date DATE,
    CONSTRAINT fk_line_po FOREIGN KEY (po_id)
        REFERENCES purchase_orders(po_id) ON DELETE CASCADE,
    CONSTRAINT fk_line_item FOREIGN KEY (item_id)
        REFERENCES inventory_items(item_id) ON DELETE RESTRICT,
    CONSTRAINT uq_line_po_number UNIQUE (po_id, line_number),
    CONSTRAINT ck_line_number CHECK (line_number > 0),
    CONSTRAINT ck_line_quantity CHECK (quantity > 0),
    CONSTRAINT ck_line_price CHECK (unit_price >= 0),
    CONSTRAINT ck_line_expected_date CHECK (
        length(CAST(expected_delivery_date AS TEXT)) = 10
    ),
    CONSTRAINT ck_line_actual_date CHECK (
        actual_delivery_date IS NULL
        OR length(CAST(actual_delivery_date AS TEXT)) = 10
    )
);

CREATE TABLE IF NOT EXISTS audit_logs (
    audit_id INTEGER PRIMARY KEY,
    run_id VARCHAR(40) NOT NULL,
    source_row_number INTEGER,
    event_type VARCHAR(30) NOT NULL,
    severity VARCHAR(10) NOT NULL,
    message VARCHAR(500) NOT NULL,
    raw_payload TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_audit_severity CHECK (severity IN ('INFO', 'WARN', 'ERROR'))
);

CREATE INDEX IF NOT EXISTS idx_supplier_active_name
    ON suppliers(active, supplier_name);
CREATE INDEX IF NOT EXISTS idx_supplier_email
    ON suppliers(email);
CREATE INDEX IF NOT EXISTS idx_item_category_active
    ON inventory_items(category_id, active);
CREATE INDEX IF NOT EXISTS idx_item_stock_risk
    ON inventory_items(current_stock, reorder_level);
CREATE INDEX IF NOT EXISTS idx_po_supplier_date
    ON purchase_orders(supplier_id, order_date);
CREATE INDEX IF NOT EXISTS idx_po_status_date
    ON purchase_orders(po_status, order_date);
CREATE INDEX IF NOT EXISTS idx_line_item_delivery
    ON order_lines(item_id, expected_delivery_date, actual_delivery_date);
CREATE INDEX IF NOT EXISTS idx_line_po
    ON order_lines(po_id);
CREATE INDEX IF NOT EXISTS idx_audit_run_event
    ON audit_logs(run_id, event_type, severity);
