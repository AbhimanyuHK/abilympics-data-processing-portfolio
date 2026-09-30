-- Executive supplier report.
-- Expected output for the supplied 20-row dirty dataset after ingestion:
--
-- supplier_name                total_po_count  total_spend  on_time_delivery_rate_pct  average_fulfillment_duration_days
-- GreenField Office Mart       2               152500.00    100.00                     7.00
-- Vertex Tools & Hardware      2               101330.00    66.67                     10.67
-- Prime Industrial Packaging   2               80750.00     66.67                     8.67
-- Northstar Components         3               72318.75     25.00                     12.50
-- Acme Industrial Supplies     3               24410.00     75.00                     10.50
--
-- Pending delivery lines are excluded from the on-time denominator.

WITH line_metrics AS (
    SELECT
        po.supplier_id,
        po.po_id,
        po.order_date,
        ol.order_line_id,
        ol.quantity * ol.unit_price AS line_spend,
        CASE
            WHEN ol.actual_delivery_date IS NOT NULL
            THEN julianday(ol.actual_delivery_date) - julianday(po.order_date)
        END AS fulfillment_days,
        CASE
            WHEN ol.actual_delivery_date IS NOT NULL
             AND ol.actual_delivery_date <= ol.expected_delivery_date
            THEN 1 ELSE 0
        END AS on_time_flag,
        CASE
            WHEN ol.actual_delivery_date IS NOT NULL THEN 1 ELSE 0
        END AS delivered_flag
    FROM purchase_orders po
    JOIN order_lines ol ON ol.po_id = po.po_id
),
supplier_metrics AS (
    SELECT
        s.supplier_name,
        COUNT(DISTINCT lm.po_id) AS total_po_count,
        ROUND(SUM(lm.line_spend), 2) AS total_spend,
        ROUND(
            100.0 * SUM(lm.on_time_flag)
            / NULLIF(SUM(lm.delivered_flag), 0),
            2
        ) AS on_time_delivery_rate_pct,
        ROUND(AVG(lm.fulfillment_days), 2)
            AS average_fulfillment_duration_days
    FROM suppliers s
    LEFT JOIN line_metrics lm ON lm.supplier_id = s.supplier_id
    GROUP BY s.supplier_id, s.supplier_name
)
SELECT
    supplier_name,
    total_po_count,
    total_spend,
    on_time_delivery_rate_pct,
    average_fulfillment_duration_days
FROM supplier_metrics
ORDER BY total_spend DESC, supplier_name;
