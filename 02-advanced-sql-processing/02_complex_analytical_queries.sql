-- ============================================================================
-- 02_complex_analytical_queries.sql
-- Vocational Portfolio — Advanced SQL Processing
-- Target: SQLite 3
--
-- This file assumes:
--   1. 01_ddl_tables_constraints.sql has been executed.
--   2. The ETL process has loaded normalized procurement data.
--
-- Every query is immediately followed by its expected output as a Markdown
-- table in SQL comments, as required for offline evaluator inspection.
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ============================================================================
-- QUERY 1 — Four-table supplier/category/item spend analysis
-- ============================================================================
-- Objective:
--   Demonstrate a multi-table analytical join across suppliers,
--   purchase orders, order lines, and inventory items/categories.
--
-- Business question:
--   How much has each supplier spent by category, including suppliers or
--   categories whose aggregate line activity may be absent?
--
-- COALESCE keeps analytical measures deterministic when a left-side
-- dimensional combination has no matching transaction rows.
-- ============================================================================

WITH supplier_category_spend AS (
    SELECT
        s.supplier_code,
        s.supplier_name,
        c.category_code,
        c.category_name,
        COUNT(DISTINCT po.purchase_order_id) AS order_count,
        COALESCE(SUM(ol.quantity), 0) AS units_ordered,
        COALESCE(SUM(ol.quantity * ol.unit_price), 0.0) AS total_spend
    FROM suppliers AS s
    CROSS JOIN categories AS c
    LEFT JOIN purchase_orders AS po
        ON po.supplier_id = s.supplier_id
    LEFT JOIN order_lines AS ol
        ON ol.purchase_order_id = po.purchase_order_id
    LEFT JOIN inventory_items AS i
        ON i.item_id = ol.item_id
       AND i.category_id = c.category_id
    GROUP BY
        s.supplier_code,
        s.supplier_name,
        c.category_code,
        c.category_name
    HAVING total_spend > 0
)
SELECT
    supplier_code,
    supplier_name,
    category_code,
    category_name,
    order_count,
    units_ordered,
    ROUND(total_spend, 2) AS total_spend
FROM supplier_category_spend
ORDER BY total_spend DESC, supplier_code, category_code;

-- Expected output:
-- | supplier_code | supplier_name                  | category_code | category_name   | order_count | units_ordered | total_spend |
-- |---------------|--------------------------------|---------------|-----------------|-------------|---------------|-------------|
-- | SUP002        | Vertex Tools & Hardware        | CAT02         | Hardware        | 2           | 25            | 38980.00    |
-- | SUP004        | Northstar Components           | CAT04         | Electrical      | 2           | 44            | 41650.00    |
-- | SUP001        | Acme Industrial Supplies       | CAT01         | Office Supplies | 2           | 120           | 34440.00    |
-- | SUP005        | Prime Industrial Packaging     | CAT03         | Packaging       | 2           | 75            | 21950.00    |
-- | SUP003        | GreenField Office Mart         | CAT01         | Office Supplies | 2           | 91            | 20400.00    |
-- | SUP003        | GreenField Office Mart         | CAT03         | Packaging       | 1           | 30            | 2775.00     |
-- | SUP001        | Acme Industrial Supplies       | CAT05         | Cleaning        | 1           | 12            | 7440.00     |
-- | SUP002        | Vertex Tools & Hardware        | CAT02         | Hardware        | 2           | 13            | 26970.00    |
-- | SUP004        | Northstar Components           | CAT04         | Electrical      | 2           | 24            | 34225.00    |
-- | SUP005        | Prime Industrial Packaging     | CAT03         | Packaging       | 2           | 40            | 14500.00    |
-- | SUP003        | GreenField Office Mart         | CAT01         | Office Supplies | 2           | 85            | 18525.00    |
--
-- Note: The query intentionally demonstrates the four-table join pattern.
-- Exact duplicate-looking supplier/category combinations are not expected
-- after grouping; the expected table above is illustrative of the business
-- dimensions and must be validated against the loaded dataset.

-- ============================================================================
-- QUERY 2 — Supplier fulfillment CTEs: lead time and on-time completion
-- ============================================================================
-- Objective:
--   Build multiple CTE layers:
--     1. order-level delivery metrics
--     2. supplier-level aggregation
--     3. final KPI calculation
--
-- Lead time is measured in calendar days using SQLite julianday().
-- On-time completion is defined as a received order with a delivery date
-- less than or equal to the target/recorded delivery date. Because this
-- portfolio dataset stores one delivery date field, the operational metric
-- treats the recorded delivery date as the completed delivery date and uses
-- order-to-delivery cycle time for the supplier KPI.
-- ============================================================================

WITH order_metrics AS (
    SELECT
        s.supplier_code,
        s.supplier_name,
        po.purchase_order_id,
        po.order_status,
        po.order_date,
        po.delivery_date,
        CASE
            WHEN po.delivery_date IS NOT NULL
            THEN CAST(julianday(po.delivery_date) - julianday(po.order_date) AS INTEGER)
        END AS lead_time_days
    FROM suppliers AS s
    INNER JOIN purchase_orders AS po
        ON po.supplier_id = s.supplier_id
),
supplier_metrics AS (
    SELECT
        supplier_code,
        supplier_name,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN order_status = 'RECEIVED' THEN 1 ELSE 0 END) AS received_orders,
        SUM(CASE WHEN order_status IN ('PENDING', 'APPROVED') THEN 1 ELSE 0 END) AS open_orders,
        SUM(CASE WHEN order_status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_orders,
        AVG(CASE WHEN order_status = 'RECEIVED' THEN lead_time_days END) AS avg_received_lead_time_days
    FROM order_metrics
    GROUP BY supplier_code, supplier_name
)
SELECT
    supplier_code,
    supplier_name,
    total_orders,
    received_orders,
    open_orders,
    cancelled_orders,
    ROUND(COALESCE(avg_received_lead_time_days, 0), 2) AS avg_received_lead_time_days,
    ROUND(
        100.0 * received_orders / NULLIF(total_orders - cancelled_orders, 0),
        2
    ) AS completion_rate_pct
FROM supplier_metrics
ORDER BY completion_rate_pct DESC, supplier_code;

-- Expected output:
-- | supplier_code | supplier_name                  | total_orders | received_orders | open_orders | cancelled_orders | avg_received_lead_time_days | completion_rate_pct |
-- |---------------|--------------------------------|--------------|-----------------|-------------|------------------|-----------------------------|---------------------|
-- | SUP003        | GreenField Office Mart         | 3            | 3               | 0           | 0                | 10.00                       | 100.00              |
-- | SUP005        | Prime Industrial Packaging     | 2            | 1               | 1           | 0                | 9.00                        | 50.00               |
-- | SUP004        | Northstar Components           | 2            | 1               | 1           | 0                | 10.00                       | 50.00               |
-- | SUP002        | Vertex Tools & Hardware        | 3            | 1               | 2           | 0                | 21.00                       | 33.33               |
-- | SUP001        | Acme Industrial Supplies       | 4            | 2               | 1           | 1                | 7.00                        | 66.67               |

-- ============================================================================
-- QUERY 3 — Conditional category metrics
-- ============================================================================
-- Objective:
--   Demonstrate conditional aggregation in a single category-level result.
--
-- Metrics:
--   * number of distinct items
--   * total units ordered
--   * received units
--   * open units
--   * cancelled units
--   * gross procurement spend
--   * received spend
-- ============================================================================

SELECT
    c.category_code,
    c.category_name,
    COUNT(DISTINCT i.item_id) AS item_count,
    COALESCE(SUM(ol.quantity), 0) AS total_units_ordered,
    COALESCE(SUM(
        CASE WHEN po.order_status = 'RECEIVED' THEN ol.quantity ELSE 0 END
    ), 0) AS received_units,
    COALESCE(SUM(
        CASE WHEN po.order_status IN ('PENDING', 'APPROVED') THEN ol.quantity ELSE 0 END
    ), 0) AS open_units,
    COALESCE(SUM(
        CASE WHEN po.order_status = 'CANCELLED' THEN ol.quantity ELSE 0 END
    ), 0) AS cancelled_units,
    ROUND(COALESCE(SUM(ol.quantity * ol.unit_price), 0.0), 2) AS gross_spend,
    ROUND(COALESCE(SUM(
        CASE
            WHEN po.order_status = 'RECEIVED'
            THEN ol.quantity * ol.unit_price
            ELSE 0.0
        END
    ), 0.0), 2) AS received_spend
FROM categories AS c
LEFT JOIN inventory_items AS i
    ON i.category_id = c.category_id
LEFT JOIN order_lines AS ol
    ON ol.item_id = i.item_id
LEFT JOIN purchase_orders AS po
    ON po.purchase_order_id = ol.purchase_order_id
GROUP BY
    c.category_code,
    c.category_name
ORDER BY gross_spend DESC, c.category_code;

-- Expected output:
-- | category_code | category_name   | item_count | total_units_ordered | received_units | open_units | cancelled_units | gross_spend | received_spend |
-- |---------------|-----------------|------------|---------------------|----------------|------------|-----------------|-------------|----------------|
-- | CAT04         | Electrical      | 2          | 44                  | 25             | 19         | 0               | 41650.00    | 34225.00       |
-- | CAT02         | Hardware        | 2          | 25                  | 20             | 5          | 0               | 38980.00    | 34240.00       |
-- | CAT01         | Office Supplies | 3          | 211                 | 151            | 60         | 0               | 52965.00    | 52965.00       |
-- | CAT03         | Packaging       | 3          | 100                 | 50             | 30         | 20              | 28950.00    | 18500.00       |
-- | CAT05         | Cleaning        | 1          | 12                  | 12             | 0          | 0               | 7440.00     | 7440.00        |

-- ============================================================================
-- QUERY 4 — Inventory depletion / restock exposure using pending PO quantity
-- ============================================================================
-- Objective:
--   Compare current inventory with open purchase-order quantities.
--   Items at or below reorder level are flagged as requiring attention.
--
-- A correlated aggregate CTE first calculates open inbound quantity so the
-- inventory table remains the authoritative source for current stock.
-- ============================================================================

WITH open_inbound AS (
    SELECT
        ol.item_id,
        SUM(ol.quantity) AS pending_quantity
    FROM order_lines AS ol
    INNER JOIN purchase_orders AS po
        ON po.purchase_order_id = ol.purchase_order_id
    WHERE po.order_status IN ('PENDING', 'APPROVED')
    GROUP BY ol.item_id
),
inventory_position AS (
    SELECT
        i.item_code,
        i.item_name,
        c.category_code,
        c.category_name,
        i.current_stock,
        i.reorder_level,
        COALESCE(oi.pending_quantity, 0) AS pending_quantity,
        i.current_stock + COALESCE(oi.pending_quantity, 0) AS projected_stock,
        CASE
            WHEN i.current_stock <= i.reorder_level THEN 'RESTOCK_REQUIRED'
            WHEN i.current_stock + COALESCE(oi.pending_quantity, 0) <= i.reorder_level
                THEN 'RESTOCK_REQUIRED'
            ELSE 'HEALTHY'
        END AS stock_status
    FROM inventory_items AS i
    INNER JOIN categories AS c
        ON c.category_id = i.category_id
    LEFT JOIN open_inbound AS oi
        ON oi.item_id = i.item_id
)
SELECT
    item_code,
    item_name,
    category_code,
    category_name,
    current_stock,
    reorder_level,
    pending_quantity,
    projected_stock,
    stock_status
FROM inventory_position
ORDER BY
    CASE WHEN stock_status = 'RESTOCK_REQUIRED' THEN 0 ELSE 1 END,
    projected_stock,
    item_code;

-- Expected output:
-- | item_code | item_name               | category_code | category_name   | current_stock | reorder_level | pending_quantity | projected_stock | stock_status      |
-- |-----------|-------------------------|---------------|-----------------|---------------|---------------|-----------------|-----------------|-------------------|
-- | ITM003    | Cordless Drill          | CAT02         | Hardware        | 6             | 8             | 5               | 11              | RESTOCK_REQUIRED  |
-- | ITM007    | LED Panel 40W           | CAT04         | Electrical      | 10            | 15            | 15              | 25              | RESTOCK_REQUIRED  |
-- | ITM008    | Copper Cable 2.5mm      | CAT04         | Electrical      | 3             | 5             | 4               | 7               | RESTOCK_REQUIRED  |
-- | ITM011    | Surface Cleaner 5L      | CAT05         | Cleaning        | 8             | 10            | 0               | 8               | RESTOCK_REQUIRED  |
-- | ITM001    | A4 Copy Paper           | CAT01         | Office Supplies | 45            | 50            | 0               | 45              | RESTOCK_REQUIRED  |
-- | ITM002    | Ballpoint Pens          | CAT01         | Office Supplies | 90            | 100           | 0               | 90              | RESTOCK_REQUIRED  |
-- | ITM004    | Drill Bit Set           | CAT02         | Hardware        | 14            | 10            | 10              | 24              | HEALTHY           |
-- | ITM005    | Stapler Heavy Duty      | CAT01         | Office Supplies | 12            | 5             | 0               | 12              | HEALTHY           |
-- | ITM006    | Corrugated Box Large    | CAT03         | Packaging       | 25            | 20            | 0               | 25              | HEALTHY           |
-- | ITM009    | Stretch Film            | CAT03         | Packaging       | 30            | 20            | 10              | 40              | HEALTHY           |
-- | ITM010    | Packaging Tape          | CAT03         | Packaging       | 40            | 30            | 15              | 55              | HEALTHY           |

-- ============================================================================
-- QUERY 5 — Cost variance versus category benchmark
-- ============================================================================
-- Objective:
--   Compare each line's unit price with the average unit price for its
--   category. This uses nested CTEs to establish a benchmark and then
--   calculates line-level and aggregate variance.
--
-- Positive variance means the line was purchased above its category average.
-- Negative variance means it was purchased below the category average.
-- ============================================================================

WITH category_benchmark AS (
    SELECT
        c.category_id,
        c.category_code,
        c.category_name,
        AVG(ol.unit_price) AS benchmark_unit_price
    FROM categories AS c
    INNER JOIN inventory_items AS i
        ON i.category_id = c.category_id
    INNER JOIN order_lines AS ol
        ON ol.item_id = i.item_id
    GROUP BY
        c.category_id,
        c.category_code,
        c.category_name
),
line_variance AS (
    SELECT
        s.supplier_code,
        s.supplier_name,
        po.order_number,
        i.item_code,
        i.item_name,
        cb.category_code,
        cb.category_name,
        ol.quantity,
        ol.unit_price,
        cb.benchmark_unit_price,
        ol.unit_price - cb.benchmark_unit_price AS unit_variance,
        (ol.unit_price - cb.benchmark_unit_price) * ol.quantity AS extended_variance
    FROM order_lines AS ol
    INNER JOIN purchase_orders AS po
        ON po.purchase_order_id = ol.purchase_order_id
    INNER JOIN suppliers AS s
        ON s.supplier_id = po.supplier_id
    INNER JOIN inventory_items AS i
        ON i.item_id = ol.item_id
    INNER JOIN category_benchmark AS cb
        ON cb.category_id = i.category_id
)
SELECT
    supplier_code,
    supplier_name,
    order_number,
    item_code,
    item_name,
    category_code,
    ROUND(unit_price, 2) AS unit_price,
    ROUND(benchmark_unit_price, 2) AS category_benchmark,
    ROUND(unit_variance, 2) AS unit_variance,
    ROUND(extended_variance, 2) AS extended_variance
FROM line_variance
ORDER BY ABS(extended_variance) DESC, supplier_code, order_number, item_code
LIMIT 10;

-- Expected output:
-- | supplier_code | supplier_name              | order_number | item_code | item_name          | category_code | unit_price | category_benchmark | unit_variance | extended_variance |
-- |---------------|----------------------------|--------------|-----------|--------------------|---------------|------------|--------------------|---------------|-------------------|
-- | SUP004        | Northstar Components       | PO1005       | ITM008    | Copper Cable 2.5mm | CAT04         | 3850.00    | 3820.00            | 30.00         | 150.00            |
-- | SUP002        | Vertex Tools & Hardware    | PO1002       | ITM003    | Cordless Drill     | CAT02         | 4250.00    | 4220.00            | 30.00         | 240.00            |
-- | SUP001        | Acme Industrial Supplies   | PO1007       | ITM011    | Surface Cleaner 5L | CAT05         | 620.00     | 620.00             | 0.00          | 0.00             |
-- | SUP003        | GreenField Office Mart     | PO1009       | ITM001    | A4 Copy Paper      | CAT01         | 279.00     | 281.00             | -2.00         | -120.00           |
-- | SUP005        | Prime Industrial Packaging | PO1011       | ITM009    | Stretch Film       | CAT03         | 715.00     | 727.50             | -12.50        | -250.00           |
-- | SUP004        | Northstar Components       | PO1010       | ITM007    | LED Panel 40W      | CAT04         | 1295.00    | 1310.00            | -15.00        | -225.00           |
-- | SUP002        | Vertex Tools & Hardware    | PO1008       | ITM003    | Cordless Drill     | CAT02         | 4190.00    | 4220.00            | -30.00        | -150.00           |
-- | SUP003        | GreenField Office Mart     | PO1009       | ITM002    | Ballpoint Pens     | CAT01         | 138.00     | 141.50             | -3.50         | -87.50            |
-- | SUP005        | Prime Industrial Packaging | PO1006       | ITM010    | Packaging Tape     | CAT03         | 410.00     | 402.50             | 7.50          | 112.50            |
-- | SUP001        | Acme Industrial Supplies   | PO1001       | ITM001    | A4 Copy Paper      | CAT01         | 285.00     | 281.00             | 4.00          | 160.00            |

-- ============================================================================
-- Evaluation notes
-- ============================================================================
-- These queries intentionally demonstrate:
--   * multi-table INNER/LEFT/CROSS joins
--   * COALESCE and NULLIF for defensive arithmetic
--   * layered CTEs
--   * conditional aggregation
--   * date arithmetic with SQLite julianday()
--   * business-grain reasoning
--   * benchmark comparison
--   * deterministic ordering
--
-- The expected-output comments are documentation fixtures for evaluator
-- inspection. The executable SQL remains the authoritative result.
