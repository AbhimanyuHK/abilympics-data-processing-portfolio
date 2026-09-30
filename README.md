# Abilympics Data Processing Portfolio

**Repository:** abilympics-data-processing-portfolio  
**Candidate:** Abhimanyu H K  
**Profile:** Senior Data Engineer | 9+ years professional experience  
**Target vocational trade:** ICT — Data Management and Processing  
**Canonical execution target:** Offline SQLite 3 workstation workflow

## Executive Overview

This repository is an independently developed technical portfolio demonstrating practical database and data-processing capability for vocational assessment.

The implementation is intentionally grounded in workstation-level relational database work:

- flat-file analysis and 1NF → 2NF → 3NF decomposition;
- BCNF-oriented dependency reasoning;
- production-style DDL with primary keys, foreign keys, uniqueness, checks, delete behavior, and indexes;
- multi-table analytical SQL;
- CTEs, subqueries, conditional aggregation, and COALESCE;
- DENSE_RANK, ROW_NUMBER, LAG, LEAD, SUM OVER, and NTILE;
- dirty CSV ingestion and deterministic cleansing;
- rejected-row auditing;
- operational delivery metrics and inventory risk scoring;
- executive supplier reporting.

The procurement scenario is synthetic and independently designed. It is not an official competition task or a reproduction of a confidential task assignment.

## Candidate Profile

**Abhimanyu H K**

Senior Data Engineer with 9+ years of professional experience across data engineering, analytics engineering, database systems, automation, and production data platforms.

For this portfolio, enterprise experience is deliberately expressed through an offline, vocationally focused implementation rather than cloud architecture. The objective is to make relational design, data quality, SQL reasoning, and reporting directly inspectable by a technical evaluator.

## Competency Mapping Matrix

| Competency | Repository evidence |
|---|---|
| Relational schema architecture | 01-schema-normalization-3nf/normalization_walkthrough.md |
| 1NF / 2NF / 3NF / BCNF reasoning | 01-schema-normalization-3nf/normalization_walkthrough.md |
| Production DDL | 01-schema-normalization-3nf/01_ddl_tables_constraints.sql |
| PK/FK/UNIQUE/CHECK constraints | 01-schema-normalization-3nf/01_ddl_tables_constraints.sql |
| Referential delete behavior | ON DELETE RESTRICT and ON DELETE CASCADE in DDL |
| Indexing | Foreign-key and operational composite indexes in DDL |
| Dirty-data realism | 01-schema-normalization-3nf/raw_procurement_data.csv |
| Cleansing and ingestion | 03-data-cleansing-and-etl/ingest_and_cleanse.py |
| Audit/rejection handling | audit_logs plus ROW_REJECTED events |
| Complex joins | 02-advanced-sql-processing/02_complex_analytical_queries.sql |
| CTE processing | Multi-level line → PO → supplier CTE |
| Conditional aggregation | Supplier delivery success-rate query |
| Subquery analysis | Item price variance against category average |
| Window functions | 02-advanced-sql-processing/03_window_and_aggregations.sql |
| Executive reporting | 04-reporting-and-business-intelligence/executive_summary_report.sql |

## Architecture

    DIRTY FLAT CSV
           |
           v
    +-----------------------+
    | Python ingestion      |
    | parse / clean / check |
    +-----------+-----------+
                |
        +-------+-------+
        |               |
     valid           invalid
        |               |
        v               v
    normalized       AUDIT_LOGS
      database
        |
        +--------------------+
        |                    |
    transactional       analytical SQL
      tables             and reporting
        |
        v
    management outputs

## Entity-Relationship Diagram

Crow's Foot relationships:

    CATEGORIES        1 ─────────────< N INVENTORY_ITEMS
    SUPPLIERS         1 ─────────────< N PURCHASE_ORDERS
    PURCHASE_ORDERS   1 ─────────────< N ORDER_LINES
    INVENTORY_ITEMS   1 ─────────────< N ORDER_LINES

    AUDIT_LOGS
      |
      +-- independent operational event table
      +-- audit_id is the primary key
      +-- run_id groups one ingestion execution

Detailed entities:

    CATEGORIES
      PK category_id
      UK category_name
      description

    SUPPLIERS
      PK supplier_id
      UK supplier_name
      contact_name
      email
      phone
      address
      active

    INVENTORY_ITEMS
      PK item_id
      UK item_code
      item_name
      FK category_id
      reorder_level
      current_stock
      standard_unit
      active

    PURCHASE_ORDERS
      PK po_id
      UK po_number
      FK supplier_id
      order_date
      currency_code
      po_status

    ORDER_LINES
      PK order_line_id
      FK po_id
      line_number
      FK item_id
      quantity
      unit_price
      expected_delivery_date
      actual_delivery_date
      UK (po_id, line_number)

    AUDIT_LOGS
      PK audit_id
      run_id
      source_row_number
      event_type
      severity
      message
      raw_payload
      created_at

## Repository Structure

    abilympics-data-processing-portfolio/
    ├── README.md
    ├── 01-schema-normalization-3nf/
    │   ├── raw_procurement_data.csv
    │   ├── normalization_walkthrough.md
    │   └── 01_ddl_tables_constraints.sql
    ├── 02-advanced-sql-processing/
    │   ├── 02_complex_analytical_queries.sql
    │   └── 03_window_and_aggregations.sql
    ├── 03-data-cleansing-and-etl/
    │   └── ingest_and_cleanse.py
    ├── 04-reporting-and-business-intelligence/
    │   └── executive_summary_report.sql
    └── procurement.db
        generated locally; not required in source control

The repository also contains earlier competition-practice material for relational travel reservations, Excel, Access, and LibreOffice Base. The procurement track above is the new executable portfolio core designed to close the implementation gaps identified in technical review.

## Canonical Environment

SQLite 3 is the canonical executable target because it is:

- offline;
- workstation friendly;
- available through Python's standard library;
- deterministic for the supplied dataset;
- suitable for demonstrating relational design and analytical SQL.

The DDL uses conservative relational constructs. The analytical query files use SQLite date functions for deterministic local date arithmetic.

The relational model can be ported to PostgreSQL without changing the entity design. PostgreSQL would use native DATE arithmetic and PostgreSQL regular-expression checks where desired. This repository does not claim that the SQLite query scripts execute unchanged on PostgreSQL.

## Prerequisites

- Python 3.10 or later.
- No third-party Python packages.
- Git recommended.
- SQLite support supplied by Python's sqlite3 module.

## Complete Local Verification

Run from the repository root.

### Step 1 — Build and load the database

    python 03-data-cleansing-and-etl/ingest_and_cleanse.py

Expected log metrics:

    rows_read=20 rows_accepted=17 rows_rejected=3

The three rejected source records contain:

1. a negative quantity;
2. a non-numeric unit price;
3. an invalid supplier/contact email.

The rejected records and reasons are written to audit_logs.

### Step 2 — Verify table counts

    python -c "import sqlite3; db=sqlite3.connect('procurement.db'); print({t: db.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0] for t in ['categories','suppliers','inventory_items','purchase_orders','order_lines','audit_logs']})"

Expected result:

    {
      'categories': 6,
      'suppliers': 5,
      'inventory_items': 11,
      'purchase_orders': 12,
      'order_lines': 17,
      'audit_logs': 21
    }

The audit count is 21:

- 17 ROW_ACCEPTED events;
- 3 ROW_REJECTED events;
- 1 RUN_SUMMARY event.

### Step 3 — Execute the complex analytical SQL

Use any SQLite client or the Python sqlite3 module to execute:

    02-advanced-sql-processing/02_complex_analytical_queries.sql

The file contains five independent statements:

1. multi-table joins with COALESCE;
2. multi-level CTE fulfillment analysis;
3. conditional supplier delivery aggregation;
4. inventory out-of-stock risk scoring;
5. item-versus-category purchase-price variance.

### Step 4 — Execute the window-function SQL

Run:

    02-advanced-sql-processing/03_window_and_aggregations.sql

The four statements demonstrate:

1. DENSE_RANK and ROW_NUMBER;
2. LAG and LEAD;
3. cumulative and rolling SUM OVER;
4. NTILE quartiles.

### Step 5 — Execute the executive report

Run:

    04-reporting-and-business-intelligence/executive_summary_report.sql

Expected output:

    supplier_name                total_po_count  total_spend  on_time_delivery_rate_pct  average_fulfillment_duration_days
    GreenField Office Mart       2               152500.00    100.00                     7.00
    Vertex Tools & Hardware      2               101330.00    66.67                     10.67
    Prime Industrial Packaging   2               80750.00     66.67                     8.67
    Northstar Components         3               72318.75     25.00                     12.50
    Acme Industrial Supplies     3               24410.00     75.00                     10.50

Pending delivery lines are excluded from the on-time denominator.

## Data Quality Controls

The ingestion boundary validates:

1. supplier composite-field structure;
2. email syntax;
3. phone normalization;
4. multiple date formats;
5. positive quantities;
6. non-negative unit prices;
7. purchase-order and line-number syntax;
8. inventory stock/reorder syntax;
9. expected delivery not preceding order date;
10. actual delivery not preceding order date;
11. duplicate supplier identities through canonicalized names;
12. duplicate item identities through item codes;
13. duplicate purchase orders through PO numbers;
14. duplicate PO lines through the composite business key;
15. foreign-key integrity through the relational schema.

Invalid source records are rejected with an audit record rather than silently coerced into trusted data.

## SQL Capability Matrix

| SQL technique | Demonstration |
|---|---|
| INNER JOIN | Supplier, PO, order-line and item analysis |
| LEFT JOIN | Missing delivery/item/category handling |
| COALESCE | Pending/missing values |
| CASE | Delivery result and risk band |
| CTE | Fulfillment-cycle decomposition |
| Conditional aggregation | Supplier success rate |
| Subquery | Item-vs-category price variance |
| DENSE_RANK | Top-N category spend |
| ROW_NUMBER | Deterministic category ordering |
| LAG | Month-over-month variance |
| LEAD | Next-month trend context |
| SUM OVER | Cumulative and rolling supplier spend |
| NTILE | Supplier lead-time quartiles |

## Executive Reporting

The management report answers:

1. How many purchase orders does each supplier have?
2. How much has been spent with each supplier?
3. What proportion of delivered lines were on time?
4. How long do supplier fulfillment cycles take?
5. Which operational patterns are visible from delivery and spend metrics?

The report is supplier-centric so a reviewer can see the transformation from row-level transactional data to management-level information.

## Production-Grade Design Principles

### Referential integrity

Foreign keys prevent orphaned purchase orders and order lines.

### Controlled deletion

- deleting a purchase order cascades to its order lines;
- supplier and inventory master records are protected with ON DELETE RESTRICT.

### Constraints

The DDL protects:

- positive quantity;
- non-negative unit price;
- valid active flags;
- valid PO status;
- three-character currency code;
- basic email syntax;
- date string shape;
- positive line number.

### Indexing

Foreign-key and operational filter columns are indexed. Composite indexes align with common access patterns such as supplier/date, PO status/date, and item/delivery-date analysis.

## Verification Checklist

- [x] Raw dataset contains deliberate anomalies.
- [x] 1NF, 2NF, 3NF and BCNF-oriented reasoning is documented.
- [x] DDL contains PK, FK, UNIQUE and CHECK constraints.
- [x] Referential delete behavior is explicit.
- [x] Foreign-key and operational indexes are defined.
- [x] Python ingestion uses only standard-library modules.
- [x] Invalid rows are rejected and audited.
- [x] Multi-table analytical SQL is implemented.
- [x] CTEs and subqueries are implemented.
- [x] Conditional aggregation is implemented.
- [x] DENSE_RANK and ROW_NUMBER are implemented.
- [x] LAG and LEAD are implemented.
- [x] Cumulative and rolling SUM OVER metrics are implemented.
- [x] NTILE quartiles are implemented.
- [x] Executive supplier reporting is implemented.
- [x] Canonical sample output is documented.

## Portfolio Review Guidance

The strongest evidence for a technical evaluator is:

1. normalization_walkthrough.md for relational reasoning;
2. 01_ddl_tables_constraints.sql for schema implementation;
3. raw_procurement_data.csv for messy-input realism;
4. ingest_and_cleanse.py for executable processing;
5. 02_complex_analytical_queries.sql for business SQL;
6. 03_window_and_aggregations.sql for analytical SQL depth;
7. executive_summary_report.sql for management reporting.

The portfolio should be presented as self-developed practice evidence, not as an official competition task or guaranteed representation of the final 2027 assignment.

## Scope and Authenticity Note

This is a self-developed practice and portfolio repository. It is not an official Abilympics task, official submission package, or endorsement by any competition organization.

The purpose is to demonstrate transferable vocational competencies through a reproducible synthetic procurement problem. Official task wording, tools, timing, scoring, and technical requirements may change; this repository should therefore be treated as preparation evidence rather than a prediction of a future task.

## Author

**Abhimanyu H K**  
Senior Data Engineer  
9+ years professional experience

GitHub: https://github.com/AbhimanyuHK
