# Normalization Walkthrough — Procurement Dataset

## Objective

The source file is intentionally shaped like a spreadsheet export rather than a relational database. A single row contains supplier identity, supplier contact information, item identity, category, purchase-order identity, order-line facts, delivery dates, and inventory thresholds.

The normalization target is a relational model with stable keys, atomic attributes, one fact represented once, explicit foreign-key relationships, controlled domains, and auditable ingestion.

## 1. Source anomalies

Typical raw fields include:

- supplier_details = Supplier | Contact | Email
- item_details = ItemCode - ItemName
- order_details = PO-Number / line N
- contact = Name <email> | phone
- inventory_snapshot = Stock=N; Reorder=N

The source also contains inconsistent capitalization, repeated supplier names, mixed phone formats, mixed date formats, numeric values containing text, missing actual delivery dates, and deliberately invalid rows.

## 2. First Normal Form — 1NF

1NF requires atomic attributes and no repeating groups.

The combined source fields are decomposed into atomic attributes.

Supplier facts become:

- supplier_name
- contact_name
- email
- phone

Item facts become:

- item_code
- item_name
- category_name
- current_stock
- reorder_level

Purchase-order facts become:

- po_number
- supplier
- order_date

Order-line facts become:

- line_number
- item
- quantity
- unit_price
- expected_delivery_date
- actual_delivery_date

A useful business candidate key for a purchase-order line is:

(po_number, line_number)

The line number is only unique within its purchase order.

## 3. Second Normal Form — 2NF

2NF requires 1NF and removal of partial dependencies on part of a composite candidate key.

For the conceptual source relation keyed by:

(po_number, line_number)

the following facts depend only on po_number:

- supplier
- order_date

The following facts depend on item identity:

- item_name
- category
- reorder_level
- current_stock

The following facts depend on the complete PO-line identity:

- quantity
- unit_price
- expected_delivery_date
- actual_delivery_date

Therefore:

- purchase-order facts move to purchase_orders;
- item facts move to inventory_items;
- line-specific facts remain in order_lines.

This eliminates partial dependencies.

## 4. Third Normal Form — 3NF

3NF requires that non-key attributes do not depend transitively on another non-key attribute.

### Supplier dependency

Do not store supplier_name and supplier_email on every order line.

Instead:

purchase_orders.supplier_id -> suppliers.supplier_id

Supplier name, contact, email, phone, and address are maintained once in suppliers.

### Category dependency

Do not repeat category metadata across purchase lines.

Instead:

inventory_items.category_id -> categories.category_id

### Purchase-order dependency

Do not repeat supplier and order date on every order line.

Instead:

order_lines.po_id -> purchase_orders.po_id

### Audit dependency

audit_logs is an operational event table. audit_id is its key and the remaining columns describe that event. It is not a transactional source of truth.

## 5. BCNF-oriented review

The main candidate keys are:

Table: categories
- category_id
- category_name

Table: suppliers
- supplier_id
- supplier_name

Table: inventory_items
- item_id
- item_code

Table: purchase_orders
- po_id
- po_number

Table: order_lines
- order_line_id
- (po_id, line_number)

Table: audit_logs
- audit_id

Unique constraints enforce the alternate business keys.

There is no non-key determinant used to describe another non-key attribute in the transactional design. The design is therefore suitable for a BCNF-oriented technical review rather than merely a superficial 3NF claim.

## 6. Final relational schema

CATEGORIES
  category_id PK
  category_name UQ
        |
        | 1:N
        v
INVENTORY_ITEMS
  item_id PK
  item_code UQ
  category_id FK
  reorder_level
  current_stock
        |
        | 1:N
        v
ORDER_LINES
  order_line_id PK
  po_id FK
  line_number
  item_id FK
  quantity
  unit_price
  expected_delivery_date
  actual_delivery_date
        ^
        | N:1
        |
PURCHASE_ORDERS
  po_id PK
  po_number UQ
  supplier_id FK
  order_date
        ^
        | N:1
        |
SUPPLIERS
  supplier_id PK
  supplier_name UQ
  contact_name
  email
  phone
  address

AUDIT_LOGS
  audit_id PK
  run_id
  source_row_number
  event_type
  severity
  message
  raw_payload
  created_at

## 7. Design decisions

### Surrogate keys

Integer surrogate keys provide stable foreign-key joins and compact indexes. Business identifiers remain protected by unique constraints.

### Purchase-order status

PO status is derived by the ingestion process from line delivery state. This prevents an unreliable free-text source status from becoming the system of record.

### Controlled category domain

Categories are reference data because the category is a reusable business concept.

### Inventory thresholds

Current stock and reorder level belong to inventory_items because they are item-level operational facts used by risk analysis.

### Auditability

Rejected records are never silently discarded. Each rejection is recorded with the source row number, reason, and raw payload.

## 8. Result

The normalized model separates master data from transaction data, removes repeated supplier and item facts, represents purchase orders and lines at the correct grain, protects relationships with foreign keys, and creates an auditable boundary between dirty input and trusted relational data.
