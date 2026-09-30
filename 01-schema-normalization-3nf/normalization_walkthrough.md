# Normalization Walkthrough — Procurement and Inventory Portfolio

## 1. Purpose

This document converts the intentionally messy procurement worksheet into a relational design suitable for SQLite 3 offline evaluation.

The source file, `raw_procurement_data.csv`, deliberately combines supplier master data, category data, inventory data, purchase-order headers, and purchase-order line data in one flat structure. The objective is to demonstrate a controlled progression from **0NF → 1NF → 2NF → 3NF**, while preserving business meaning and enforcing referential integrity.

The target design contains five relations:

1. `suppliers`
2. `categories`
3. `inventory_items`
4. `purchase_orders`
5. `order_lines`

SQLite is the execution target. The design uses relationally portable concepts wherever possible, with SQLite-compatible `INTEGER PRIMARY KEY AUTOINCREMENT` syntax where explicitly required by the portfolio specification.

---

## 2. Source Data Profile

The raw worksheet has one record per purchase-order line, but repeats higher-level attributes on every line belonging to the same supplier or purchase order.

### Raw attributes

| Attribute | Business meaning | Intended owner after normalization |
|---|---|---|
| supplier_code | Stable supplier business identifier | suppliers |
| supplier_name | Supplier name | suppliers |
| contact_name | Primary supplier contact | suppliers |
| phone | Supplier phone | suppliers |
| email | Supplier email | suppliers |
| supplier_location | Combined city/state | suppliers |
| supplier_status | Supplier lifecycle state | suppliers |
| category_code | Item category identifier | categories |
| category_name | Category description | categories |
| item_code | Inventory item identifier | inventory_items |
| item_name | Inventory item name | inventory_items |
| unit_of_measure | Stock/order unit | inventory_items |
| reorder_level | Reorder threshold | inventory_items |
| current_stock | Current stock balance | inventory_items |
| order_number | Purchase-order business identifier | purchase_orders |
| order_date | Purchase-order date | purchase_orders |
| delivery_date | Actual/expected delivery date | purchase_orders |
| order_status | Purchase-order lifecycle state | purchase_orders |
| quantity | Quantity purchased | order_lines |
| unit_price | Agreed unit purchase price | order_lines |

The raw file intentionally contains date variants such as `2026-03-15`, `15/03/2026`, and `Mar 15, 2026`, plus inconsistent casing, whitespace, phone punctuation, and combined location values. These are cleansing concerns, not reasons to retain the denormalized structure.

---

## 3. Functional Dependencies

The main dependencies discovered from the business semantics are:

### Supplier

`supplier_code → supplier_name, contact_name, phone, email, city, state, supplier_status`

A supplier code identifies one supplier master record.

### Category

`category_code → category_name, category_status`

A category code identifies one category.

### Inventory item

`item_code → item_name, category_code, unit_of_measure, reorder_level, current_stock, item_status`

An item code identifies one inventory item and its category relationship.

### Purchase order

`order_number → supplier_code, order_date, delivery_date, order_status`

An order number identifies one purchase-order header.

### Order line

Under the business rule that an item appears at most once on a purchase order:

`(order_number, item_code) → quantity, unit_price`

The final implementation uses a surrogate `order_line_id` as the physical primary key while retaining the business relationship between purchase order and item.

---

# 4. 0NF — Unnormalized Form

The supplied CSV is intentionally close to an operational spreadsheet rather than a relational model.

A conceptual 0NF record looks like:

```text
Supplier
  ├─ code
  ├─ name
  ├─ contact
  ├─ phone
  ├─ email
  ├─ location
  └─ status

Category
  ├─ code
  └─ name

Inventory Item
  ├─ code
  ├─ name
  ├─ unit
  ├─ reorder level
  └─ current stock

Purchase Order
  ├─ number
  ├─ date
  ├─ delivery date
  └─ status

Order Line
  ├─ quantity
  └─ unit price
```

All of these facts are physically stored in the same row.

### Problems

The same supplier information is repeated across multiple purchase orders and line items. Category and item master attributes are also repeated.

For example, `SUP001` occurs on several rows. Its name, contact, phone, email, location, and status therefore have multiple physical copies.

This creates:

- **Update anomaly:** changing a supplier phone requires finding every row containing that supplier.
- **Insertion anomaly:** a new supplier cannot naturally be represented if the flat structure requires a purchase order and item at the same time.
- **Deletion anomaly:** deleting the final purchase-order line for a supplier can accidentally remove the only stored copy of that supplier's master information.
- **Storage redundancy:** repeated text consumes space and increases the probability of inconsistent values.
- **Data-quality ambiguity:** different formatting of the same phone, email, date, or location can appear to represent different values.

---

# 5. 1NF — Atomic Attributes

First Normal Form requires each attribute to contain an atomic value and each record to represent a well-defined occurrence.

The cleansing process therefore separates combined and formatted values before loading the normalized model.

### 1NF transformations

| Raw issue | 1NF treatment |
|---|---|
| `supplier_location = "Bengaluru, Karnataka"` | Split into `city = "Bengaluru"` and `state = "Karnataka"` |
| `080-23456789` | Normalize to a canonical phone representation |
| Mixed-case emails | Normalize case and whitespace |
| `15/03/2026` | Parse to ISO `2026-03-15` |
| `Mar 15, 2026` | Parse to ISO `2026-03-15` |
| Multiple rows for one PO | Treat each row as one order-line occurrence |
| Multiple rows for one item | Maintain one item master and reference it from lines |

The 1NF relation can be viewed conceptually as:

```text
R(
  supplier_code,
  supplier_name,
  contact_name,
  phone,
  email,
  city,
  state,
  supplier_status,
  category_code,
  category_name,
  item_code,
  item_name,
  unit_of_measure,
  reorder_level,
  current_stock,
  order_number,
  order_date,
  delivery_date,
  order_status,
  quantity,
  unit_price
)
```

### Candidate key at the line-grain

For the supplied business rule, a natural candidate key is:

`(order_number, item_code)`

This assumes an item can occur only once within a purchase order. It identifies the line while avoiding dependence on descriptive attributes.

The production schema additionally introduces `order_line_id` as a surrogate primary key. A surrogate key simplifies foreign-key references and remains stable if a business identifier changes. The business uniqueness rule can still be enforced with a `UNIQUE` constraint on `(purchase_order_id, item_id)` if duplicate item lines are not permitted.

---

# 6. 2NF — Remove Partial Dependencies

Second Normal Form requires 1NF plus removal of attributes that depend on only part of a composite candidate key.

Using the conceptual candidate key:

`(order_number, item_code)`

we can classify dependencies.

### Attributes dependent on order number

```text
order_number
  → supplier_code
  → order_date
  → delivery_date
  → order_status
```

These are purchase-order header facts. They do not depend on the item.

### Attributes dependent on item code

```text
item_code
  → item_name
  → category_code
  → category_name
  → unit_of_measure
  → reorder_level
  → current_stock
```

These are inventory/item-master facts. They do not depend on the order.

### Attributes dependent on the complete line key

```text
(order_number, item_code)
  → quantity
  → unit_price
```

Quantity and unit price describe the specific item occurrence on that purchase order.

### 2NF decomposition

The flat relation is decomposed into:

```text
PURCHASE_ORDER(
    order_number,
    supplier_code,
    order_date,
    delivery_date,
    order_status
)

INVENTORY_ITEM(
    item_code,
    item_name,
    category_code,
    category_name,
    unit_of_measure,
    reorder_level,
    current_stock
)

ORDER_LINE(
    order_number,
    item_code,
    quantity,
    unit_price
)
```

Supplier and category are still candidates for further decomposition because their descriptive attributes have their own determinants.

---

# 7. 3NF — Remove Transitive Dependencies

Third Normal Form requires that non-key attributes depend on the key, the whole key, and nothing but the key.

Two important transitive dependency chains exist in the intermediate model.

## 7.1 Supplier dependency

Instead of storing supplier details with every order:

```text
order_number
  → supplier_code
  → supplier_name
  → contact_name
  → phone
  → email
  → city
  → state
  → supplier_status
```

supplier attributes are moved into `suppliers`.

The purchase order retains only the supplier foreign key.

## 7.2 Category dependency

Instead of storing the category name with every item:

```text
item_code
  → category_code
  → category_name
```

category attributes are moved into `categories`.

The inventory item retains only the category foreign key.

This removes transitive dependencies from the operational relations.

---

# 8. Final 3NF Schema

## 8.1 suppliers

**Primary key:** `supplier_id`

**Business candidate key:** `supplier_code`

Attributes:

```text
supplier_id
supplier_code
supplier_name
contact_name
phone
email
city
state
supplier_status
```

Functional dependency:

`supplier_id → all supplier attributes`

and:

`supplier_code → all supplier attributes`

because `supplier_code` is unique.

---

## 8.2 categories

**Primary key:** `category_id`

**Business candidate key:** `category_code`

Attributes:

```text
category_id
category_code
category_name
category_status
```

Functional dependency:

`category_id → category_code, category_name, category_status`

and:

`category_code → category_name, category_status`

---

## 8.3 inventory_items

**Primary key:** `item_id`

**Business candidate key:** `item_code`

**Foreign key:** `category_id → categories.category_id`

Attributes:

```text
item_id
item_code
item_name
category_id
unit_of_measure
reorder_level
current_stock
item_status
```

Functional dependency:

`item_id → all item attributes`

and:

`item_code → all item attributes`

The category name is intentionally absent. It is obtained through the foreign-key relationship to `categories`.

---

## 8.4 purchase_orders

**Primary key:** `purchase_order_id`

**Business candidate key:** `order_number`

**Foreign key:** `supplier_id → suppliers.supplier_id`

Attributes:

```text
purchase_order_id
order_number
supplier_id
order_date
delivery_date
order_status
```

Functional dependency:

`purchase_order_id → order_number, supplier_id, order_date, delivery_date, order_status`

and:

`order_number → supplier_id, order_date, delivery_date, order_status`

---

## 8.5 order_lines

**Primary key:** `order_line_id`

**Foreign keys:**

- `purchase_order_id → purchase_orders.purchase_order_id`
- `item_id → inventory_items.item_id`

Attributes:

```text
order_line_id
purchase_order_id
item_id
quantity
unit_price
```

The line's measurable facts depend on the order-line occurrence.

Under the portfolio's one-item-per-order-line business rule:

`(purchase_order_id, item_id) → quantity, unit_price`

The physical primary key remains `order_line_id`.

---

# 9. Entity Relationship Summary

The normalized dependency graph is:

```text
SUPPLIERS
   │
   │ 1 ───────< many
   ▼
PURCHASE_ORDERS
   │
   │ 1 ───────< many
   ▼
ORDER_LINES
   ▲
   │ many ─────── 1
   │
INVENTORY_ITEMS
   ▲
   │ many ─────── 1
   │
CATEGORIES
```

More precisely:

- One supplier can have many purchase orders.
- Each purchase order belongs to exactly one supplier.
- One purchase order can have many order lines.
- Each order line belongs to exactly one purchase order.
- One inventory item can occur on many order lines.
- Each inventory item belongs to exactly one category.
- One category can contain many inventory items.

The foreign-key graph therefore prevents orphaned transactional records when foreign-key enforcement is enabled.

---

# 10. Data-Type and SQLite Decisions

The target database is SQLite 3 and must run offline.

The schema uses:

| Logical type | SQLite representation | Reason |
|---|---|---|
| Surrogate identifier | `INTEGER PRIMARY KEY AUTOINCREMENT` | Required SQLite-compatible identity pattern |
| Business code | `TEXT` | Preserves leading zeros and business formatting |
| Name/contact | `TEXT` | Human-readable descriptive values |
| Quantity | `INTEGER` | Whole-unit inventory quantities |
| Price | `REAL` | Offline portfolio arithmetic and SQLite compatibility |
| Date | `TEXT` in `YYYY-MM-DD` | SQLite has no dedicated DATE storage class |
| Status | `TEXT` + `CHECK` | Explicit controlled vocabulary |

The DDL also enables:

```sql
PRAGMA foreign_keys = ON;
```

This is important because SQLite foreign-key enforcement is connection-level behavior and should not be assumed merely because foreign keys are declared.

---

# 11. Integrity Rules Derived from Normalization

Normalization determines where facts belong. Constraints then protect those facts.

### Supplier integrity

- `supplier_code` is unique and required.
- Supplier name is required.
- Status is constrained to the permitted lifecycle values.

### Category integrity

- `category_code` is unique and required.
- Category name is required.

### Inventory integrity

- `item_code` is unique.
- Category reference is required.
- Reorder level cannot be negative.
- Current stock cannot be negative.

### Purchase-order integrity

- `order_number` is unique.
- Supplier reference is required.
- Order date is required.
- Status is restricted to `PENDING`, `APPROVED`, `RECEIVED`, or `CANCELLED`.
- Delivery date cannot precede order date.

### Order-line integrity

- Purchase-order and item references are required.
- Quantity must be greater than zero.
- Unit price must be non-negative.

These rules turn the normalization model into an enforceable database contract rather than a documentation-only exercise.

---

# 12. Why the Design Is 3NF

The final relations satisfy the intended 3NF structure because:

1. Each table represents one coherent subject.
2. Every table has an explicit primary key.
3. Descriptive attributes depend on the key of their own table.
4. Supplier attributes are not repeated in purchase orders or order lines.
5. Category attributes are not repeated in inventory items or order lines.
6. Purchase-order header attributes are not repeated on every line.
7. Item-master attributes are not repeated on every transaction.
8. Transaction measures `quantity` and `unit_price` remain at order-line grain.
9. Relationships between subjects are represented through foreign keys rather than duplicated descriptive text.
10. Business identifiers remain unique and can be used for deterministic ingestion and reconciliation.

The result is a compact relational model that supports both operational integrity and analytical SQL without reintroducing the original spreadsheet redundancy.

---

# 13. Evaluation Mapping

| Evaluation capability | Evidence in this walkthrough |
|---|---|
| Identify repeating/duplicated data | 0NF analysis |
| Atomic attributes | 1NF decomposition |
| Composite-key reasoning | `(order_number, item_code)` candidate key |
| Partial dependency detection | 2NF analysis |
| Transitive dependency detection | 3NF supplier/category decomposition |
| Candidate keys | Supplier, category, item, and order business codes |
| Primary/foreign keys | Final five-table schema |
| Referential integrity | Explicit relationship model |
| Data-quality awareness | Phone, email, date, whitespace, casing, location |
| SQLite compatibility | SQLite-specific implementation decisions |

---

# 14. Final Normalized Model

```text
suppliers
---------
PK supplier_id
UQ supplier_code
supplier_name
contact_name
phone
email
city
state
supplier_status

categories
----------
PK category_id
UQ category_code
category_name
category_status

inventory_items
---------------
PK item_id
UQ item_code
item_name
FK category_id
unit_of_measure
reorder_level
current_stock
item_status

purchase_orders
---------------
PK purchase_order_id
UQ order_number
FK supplier_id
order_date
delivery_date
order_status

order_lines
-----------
PK order_line_id
FK purchase_order_id
FK item_id
quantity
unit_price
```

This five-table structure is the canonical 3NF target used by the DDL, cleansing/ETL process, analytical SQL, window analytics, executive report, and automated verifier in this portfolio.
