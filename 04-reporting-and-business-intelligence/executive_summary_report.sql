-- ============================================================================
-- executive_summary_report.sql
-- Executive Management Reporting
-- Target: SQLite 3 / ANSI SQL
--
-- Schema note:
-- The normalized schema contains one delivery_date field. Therefore the
-- on-time KPI is defined as the percentage of RECEIVED orders that have a
-- recorded delivery_date. A true planned-vs-actual SLA requires separate
-- expected and actual delivery dates.
-- ============================================================================

WITH supplier_orders AS (
    SELECT
        s.supplier_code,
        s.supplier_name,
        po.purchase_order_id,
        po.order_status,
        po.order_date,
        po.delivery_date,
        CASE
            WHEN po.delivery_date IS NOT NULL
            THEN CAST(
                julianday(po.delivery_date) - julianday(po.order_date)
                AS INTEGER
            )
        END AS delivery_lead_days
    FROM suppliers AS s
    LEFT JOIN purchase_orders AS po
        ON po.supplier_id = s.supplier_id
),
order_values AS (
    SELECT
        purchase_order_id,
        ROUND(SUM(quantity * unit_price), 2) AS order_value
    FROM order_lines
    GROUP BY purchase_order_id
)
SELECT
    so.supplier_code,
    so.supplier_name,
    COUNT(so.purchase_order_id) AS total_po_count,
    ROUND(COALESCE(SUM(ov.order_value), 0.0), 2) AS total_value_ordered_usd,
    SUM(CASE WHEN so.order_status = 'RECEIVED' THEN 1 ELSE 0 END)
        AS orders_received,
    SUM(
        CASE
            WHEN so.order_status IN ('CANCELLED', 'PENDING', 'APPROVED')
            THEN 1 ELSE 0
        END
    ) AS orders_cancelled_or_pending,
    ROUND(
        100.0
        * SUM(CASE WHEN so.order_status = 'RECEIVED' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(so.purchase_order_id), 0),
        2
    ) AS fulfillment_rate_pct,
    ROUND(
        100.0
        * SUM(
            CASE
                WHEN so.order_status = 'RECEIVED'
                     AND so.delivery_date IS NOT NULL
                THEN 1 ELSE 0
            END
        )
        / NULLIF(
            SUM(CASE WHEN so.order_status = 'RECEIVED' THEN 1 ELSE 0 END),
            0
        ),
        2
    ) AS on_time_delivery_rate_pct,
    ROUND(
        AVG(
            CASE
                WHEN so.order_status = 'RECEIVED'
                     AND so.delivery_date IS NOT NULL
                THEN so.delivery_lead_days
            END
        ),
        2
    ) AS average_delivery_lead_days
FROM supplier_orders AS so
LEFT JOIN order_values AS ov
    ON ov.purchase_order_id = so.purchase_order_id
GROUP BY
    so.supplier_code,
    so.supplier_name
ORDER BY
    total_value_ordered_usd DESC,
    so.supplier_code;

-- Expected output:
-- | supplier_code | supplier_name              | total_po_count | total_value_ordered_usd | orders_received | orders_cancelled_or_pending | fulfillment_rate_pct | on_time_delivery_rate_pct | average_delivery_lead_days |
-- |---------------|----------------------------|----------------|-------------------------|-----------------|-----------------------------|----------------------|---------------------------|-----------------------------|
-- | SUP002        | Vertex Tools & Hardware    | 3              | 80760.00                | 1               | 2                           | 33.33                | 100.00                    | 12.00                       |
-- | SUP004        | Northstar Components       | 2              | 80300.00                | 1               | 1                           | 50.00                | 100.00                    | 11.00                       |
-- | SUP005        | Prime Industrial Packaging | 2              | 39700.00                | 1               | 1                           | 50.00                | 100.00                    | 9.00                        |
-- | SUP001        | Acme Industrial Supplies   | 3              | 27790.00                | 2               | 1                           | 66.67                | 100.00                    | 7.00                        |
-- | SUP003        | GreenField Office Mart     | 3              | 26310.00                | 2               | 1                           | 66.67                | 100.00                    | 7.00                        |
