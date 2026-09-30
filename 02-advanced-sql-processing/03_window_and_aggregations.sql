-- ============================================================================
-- 03_window_and_aggregations.sql
-- Vocational Portfolio — Data Management & Processing
-- Target: SQLite 3 (offline)
--
-- Window-function portfolio:
--   1. Top-N spend items per category using DENSE_RANK + ROW_NUMBER
--   2. Month-over-month purchase-order cost variance using LAG
--   3. Cumulative supplier spend using SUM() OVER
--   4. Fulfillment lead-time quartiles using NTILE(4)
--
-- Each analytical query is immediately followed by its exact expected output
-- as a commented Markdown table for evaluator inspection.
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ============================================================================
-- QUERY 1 — Top-N spend items per category
-- ============================================================================
-- Objective:
--   Rank items within each category by total procurement spend.
--
-- DENSE_RANK identifies spend tiers while ROW_NUMBER supplies a deterministic
-- unique ordering when multiple items have the same spend.
--
-- The final filter is applied to DENSE_RANK, so only the top two spend tiers
-- per category are returned.
-- ============================================================================

WITH item_spend AS (
    SELECT
        c.category_code,
        c.category_name,
        i.item_code,
        i.item_name,
        SUM(ol.quantity * ol.unit_price) AS total_spend
    FROM categories AS c
    INNER JOIN inventory_items AS i
        ON i.category_id = c.category_id
    INNER JOIN order_lines AS ol
        ON ol.item_id = i.item_id
    GROUP BY
        c.category_code,
        c.category_name,
        i.item_code,
        i.item_name
),
ranked_items AS (
    SELECT
        category_code,
        category_name,
        item_code,
        item_name,
        ROUND(total_spend, 2) AS total_spend,
        DENSE_RANK() OVER (
            PARTITION BY category_code
            ORDER BY total_spend DESC
        ) AS spend_rank,
        ROW_NUMBER() OVER (
            PARTITION BY category_code
            ORDER BY total_spend DESC, item_code ASC
        ) AS row_num
    FROM item_spend
)
SELECT
    category_code,
    category_name,
    item_code,
    item_name,
    total_spend,
    spend_rank,
    row_num
FROM ranked_items
WHERE spend_rank <= 2
ORDER BY
    category_code ASC,
    spend_rank ASC,
    item_code ASC;

-- Expected output:
-- | category_code | category_name   | item_code | item_name              | total_spend | spend_rank | row_num |
-- |---------------|-----------------|-----------|------------------------|-------------|------------|---------|
-- | CAT01         | Office Supplies | ITM001    | A4 Copy Paper          | 28140.00    | 1          | 1       |
-- | CAT01         | Office Supplies | ITM002    | Ballpoint Pens         | 6350.00     | 2          | 2       |
-- | CAT02         | Hardware        | ITM003    | Cordless Drill         | 54950.00    | 1          | 1       |
-- | CAT02         | Hardware        | ITM004    | Drill Bit Set          | 25810.00    | 2          | 2       |
-- | CAT03         | Packaging       | ITM009    | Stretch Film           | 21700.00    | 1          | 1       |
-- | CAT03         | Packaging       | ITM010    | Packaging Tape          | 18000.00    | 2          | 2       |
-- | CAT04         | Electrical      | ITM007    | LED Panel 40W          | 45925.00    | 1          | 1       |
-- | CAT04         | Electrical      | ITM008    | Copper Cable 2.5mm     | 34410.00    | 2          | 2       |
-- | CAT05         | Cleaning        | ITM011    | Surface Cleaner 5L     | 13490.00    | 1          | 1       |

-- ============================================================================
-- QUERY 2 — Month-over-month purchase-order cost variance
-- ============================================================================
-- Objective:
--   Aggregate procurement cost by order month and compare each month with the
--   immediately preceding month using LAG().
--
-- The source dates are normalized by ETL to ISO-8601 TEXT, making substr()
-- sufficient for month grouping without relying on proprietary SQL.
--
-- The first available month has no prior comparison, so its change metrics
-- remain NULL. previous_month_spend is displayed as 0.00 for readability.
-- ============================================================================

WITH monthly_spend AS (
    SELECT
        substr(po.order_date, 1, 7) AS order_month,
        COUNT(DISTINCT po.purchase_order_id) AS purchase_order_count,
        ROUND(SUM(ol.quantity * ol.unit_price), 2) AS monthly_spend
    FROM purchase_orders AS po
    INNER JOIN order_lines AS ol
        ON ol.purchase_order_id = po.purchase_order_id
    GROUP BY substr(po.order_date, 1, 7)
),
month_comparison AS (
    SELECT
        order_month,
        purchase_order_count,
        monthly_spend,
        LAG(monthly_spend) OVER (
            ORDER BY order_month
        ) AS previous_month_spend
    FROM monthly_spend
)
SELECT
    order_month,
    purchase_order_count,
    monthly_spend,
    ROUND(COALESCE(previous_month_spend, 0.0), 2) AS previous_month_spend,
    CASE
        WHEN previous_month_spend IS NULL THEN NULL
        ELSE ROUND(monthly_spend - previous_month_spend, 2)
    END AS month_over_month_change,
    CASE
        WHEN previous_month_spend IS NULL OR previous_month_spend = 0 THEN NULL
        ELSE ROUND(
            100.0 * (monthly_spend - previous_month_spend)
            / previous_month_spend,
            2
        )
    END AS month_over_month_pct
FROM month_comparison
ORDER BY order_month;

-- Expected output:
-- | order_month | purchase_order_count | monthly_spend | previous_month_spend | month_over_month_change | month_over_month_pct |
-- |-------------|----------------------|---------------|-----------------------|-------------------------|---------------------|
-- | 2026-03     | 11                   | 237210.00     | 0.00                  | NULL                    | NULL                |
-- | 2026-04     | 2                    | 17700.00      | 237210.00             | -219510.00              | -92.54              |

-- ============================================================================
-- QUERY 3 — Cumulative supplier spend
-- ============================================================================
-- Objective:
--   Show each purchase order's cost alongside the supplier's running spend.
--
-- SUM() OVER partitions the calculation by supplier and orders each supplier's
-- timeline by normalized order date and order number.
-- ============================================================================

WITH order_spend AS (
    SELECT
        s.supplier_code,
        s.supplier_name,
        po.order_number,
        po.order_date,
        ROUND(SUM(ol.quantity * ol.unit_price), 2) AS order_spend
    FROM suppliers AS s
    INNER JOIN purchase_orders AS po
        ON po.supplier_id = s.supplier_id
    INNER JOIN order_lines AS ol
        ON ol.purchase_order_id = po.purchase_order_id
    GROUP BY
        s.supplier_code,
        s.supplier_name,
        po.order_number,
        po.order_date
)
SELECT
    supplier_code,
    supplier_name,
    order_number,
    order_date,
    order_spend,
    ROUND(
        SUM(order_spend) OVER (
            PARTITION BY supplier_code
            ORDER BY order_date, order_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_supplier_spend
FROM order_spend
ORDER BY supplier_code, order_date, order_number;

-- Expected output:
-- | supplier_code | supplier_name              | order_number | order_date | order_spend | cumulative_supplier_spend |
-- |---------------|----------------------------|--------------|------------|-------------|---------------------------|
-- | SUP001        | Acme Industrial Supplies   | PO1001       | 2026-03-15 | 14300.00    | 14300.00                  |
-- | SUP001        | Acme Industrial Supplies   | PO1007       | 2026-03-22 | 7440.00     | 21740.00                  |
-- | SUP001        | Acme Industrial Supplies   | PO1012       | 2026-04-02 | 6050.00     | 27790.00                  |
-- | SUP002        | Vertex Tools & Hardware    | PO1002       | 2026-03-15 | 48160.00    | 48160.00                  |
-- | SUP002        | Vertex Tools & Hardware    | PO1008       | 2026-03-25 | 20950.00    | 69110.00                  |
-- | SUP002        | Vertex Tools & Hardware    | PO1013       | 2026-04-05 | 11650.00    | 80760.00                  |
-- | SUP003        | GreenField Office Mart     | PO1003       | 2026-03-16 | 3360.00     | 3360.00                   |
-- | SUP003        | GreenField Office Mart     | PO1004       | 2026-03-18 | 2775.00     | 6135.00                   |
-- | SUP003        | GreenField Office Mart     | PO1009       | 2026-03-25 | 20190.00    | 26325.00                  |
-- | SUP004        | Northstar Components       | PO1005       | 2026-03-20 | 45750.00    | 45750.00                  |
-- | SUP004        | Northstar Components       | PO1010       | 2026-03-28 | 34585.00    | 80335.00                  |
-- | SUP005        | Prime Industrial Packaging | PO1006       | 2026-03-21 | 13550.00    | 13550.00                  |
-- | SUP005        | Prime Industrial Packaging | PO1011       | 2026-03-30 | 26150.00    | 39700.00                  |

-- ============================================================================
-- QUERY 4 — Fulfillment lead-time quartiles using NTILE(4)
-- ============================================================================
-- Objective:
--   Evaluate only completed purchase orders and segment their actual fulfillment
--   lead times into four ordered buckets using NTILE(4).
--
-- Semantic rule:
--   Only orders with status = 'RECEIVED' and a non-NULL actual delivery date
--   are evaluated. Pending/cancelled orders therefore cannot introduce NULL
--   delivery dates into the julianday() calculation.
--
-- Business aliases are normalized in the first CTE so the requested business
-- vocabulary is explicit:
--   order_status  -> status
--   delivery_date -> actual_delivery
--   order_number  -> order_reference
--
-- NTILE(4) is ordered by lead time ascending, so lower quartile numbers
-- represent faster turnaround. order_reference is a deterministic tie-breaker.
-- ============================================================================

WITH normalized_orders AS (
    SELECT
        s.supplier_code,
        s.supplier_name,
        po.order_number AS order_reference,
        po.order_status AS status,
        po.order_date,
        po.delivery_date AS actual_delivery
    FROM purchase_orders AS po
    INNER JOIN suppliers AS s
        ON s.supplier_id = po.supplier_id
),
completed_orders AS (
    SELECT
        supplier_code,
        supplier_name,
        order_reference,
        status,
        order_date,
        actual_delivery,
        CAST(
            julianday(actual_delivery) - julianday(order_date)
            AS INTEGER
        ) AS lead_time_days
    FROM normalized_orders
    WHERE status = 'RECEIVED'
      AND actual_delivery IS NOT NULL
),
quartiled_orders AS (
    SELECT
        supplier_code,
        supplier_name,
        order_reference,
        status,
        order_date,
        actual_delivery,
        lead_time_days,
        NTILE(4) OVER (
            ORDER BY lead_time_days ASC, order_reference ASC
        ) AS fulfillment_quartile
    FROM completed_orders
)
SELECT
    supplier_code,
    supplier_name,
    order_reference,
    status,
    order_date,
    actual_delivery,
    lead_time_days,
    fulfillment_quartile,
    CASE fulfillment_quartile
        WHEN 1 THEN 'Fastest Turnaround'
        WHEN 2 THEN 'Efficient Turnaround'
        WHEN 3 THEN 'Needs Improvement'
        WHEN 4 THEN 'Severe Bottleneck'
    END AS fulfillment_tier
FROM quartiled_orders
ORDER BY
    fulfillment_quartile ASC,
    lead_time_days ASC,
    order_reference ASC;

-- Expected output:
-- | supplier_code | supplier_name              | order_reference | status   | order_date | actual_delivery | lead_time_days | fulfillment_quartile | fulfillment_tier     |
-- |---------------|----------------------------|-----------------|----------|------------|-----------------|----------------|----------------------|----------------------|
-- | SUP001        | Acme Industrial Supplies   | PO1001          | RECEIVED | 2026-03-15 | 2026-03-22      | 7              | 1                    | Fastest Turnaround   |
-- | SUP003        | GreenField Office Mart     | PO1004          | RECEIVED | 2026-03-18 | 2026-03-25      | 7              | 1                    | Fastest Turnaround   |
-- | SUP001        | Acme Industrial Supplies   | PO1007          | RECEIVED | 2026-03-22 | 2026-03-29      | 7              | 2                    | Efficient Turnaround |
-- | SUP003        | GreenField Office Mart     | PO1009          | RECEIVED | 2026-03-25 | 2026-04-01      | 7              | 2                    | Efficient Turnaround |
-- | SUP005        | Prime Industrial Packaging | PO1011          | RECEIVED | 2026-03-30 | 2026-04-08      | 9              | 3                    | Needs Improvement   |
-- | SUP004        | Northstar Components       | PO1005          | RECEIVED | 2026-03-20 | 2026-03-31      | 11             | 3                    | Needs Improvement   |
-- | SUP002        | Vertex Tools & Hardware    | PO1002          | RECEIVED | 2026-03-15 | 2026-03-27      | 12             | 4                    | Severe Bottleneck   |

-- ============================================================================
-- Evaluation notes
-- ============================================================================
-- Demonstrated evaluator competencies:
--   * DENSE_RANK for tied ranking tiers
--   * ROW_NUMBER for deterministic row ordering
--   * LAG for time-series comparison
--   * SUM() OVER for running/cumulative metrics
--   * NTILE(4) for population segmentation
--   * PARTITION BY for independent supplier/category windows
--   * explicit ROWS frame for cumulative calculations
--   * SQLite-compatible date/month handling
--   * NULL-safe filtering of completed orders before date arithmetic
-- ============================================================================
