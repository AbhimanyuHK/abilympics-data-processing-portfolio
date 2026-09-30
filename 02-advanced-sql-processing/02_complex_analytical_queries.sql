-- 1. Multi-table outer joins with COALESCE and conditional logic.
SELECT
    po.po_number,
    COALESCE(s.supplier_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(c.category_name, 'Unclassified') AS category_name,
    COALESCE(ii.item_name, 'Unknown Item') AS item_name,
    ol.quantity,
    ROUND(ol.quantity * ol.unit_price, 2) AS line_spend,
    ol.expected_delivery_date,
    COALESCE(ol.actual_delivery_date, 'PENDING') AS actual_delivery_date,
    CASE
        WHEN ol.actual_delivery_date IS NULL THEN 'PENDING'
        WHEN ol.actual_delivery_date <= ol.expected_delivery_date THEN 'ON_TIME'
        ELSE 'LATE'
    END AS delivery_result
FROM purchase_orders po
LEFT JOIN suppliers s ON s.supplier_id = po.supplier_id
LEFT JOIN order_lines ol ON ol.po_id = po.po_id
LEFT JOIN inventory_items ii ON ii.item_id = ol.item_id
LEFT JOIN categories c ON c.category_id = ii.category_id
ORDER BY po.order_date, po.po_number, ol.line_number;

-- 2. Multi-level CTE for line -> PO -> supplier fulfillment analysis.
WITH line_cycle AS (
    SELECT
        po.po_id,
        po.po_number,
        po.supplier_id,
        po.order_date,
        ol.order_line_id,
        CASE
            WHEN ol.actual_delivery_date IS NULL THEN NULL
            ELSE CAST(
                julianday(ol.actual_delivery_date) - julianday(po.order_date)
                AS INTEGER
            )
        END AS fulfillment_days,
        CASE
            WHEN ol.actual_delivery_date IS NULL THEN 'OPEN'
            WHEN ol.actual_delivery_date <= ol.expected_delivery_date THEN 'ON_TIME'
            ELSE 'LATE'
        END AS delivery_result
    FROM purchase_orders po
    JOIN order_lines ol ON ol.po_id = po.po_id
),
po_cycle AS (
    SELECT
        po_id,
        po_number,
        supplier_id,
        MIN(fulfillment_days) AS fastest_line_days,
        MAX(fulfillment_days) AS slowest_line_days,
        AVG(fulfillment_days) AS average_line_days,
        SUM(CASE WHEN delivery_result = 'LATE' THEN 1 ELSE 0 END) AS late_lines,
        COUNT(*) AS total_lines
    FROM line_cycle
    GROUP BY po_id, po_number, supplier_id
),
supplier_cycle AS (
    SELECT
        s.supplier_name,
        COUNT(pc.po_id) AS purchase_orders,
        ROUND(AVG(pc.average_line_days), 2) AS avg_po_fulfillment_days,
        SUM(pc.late_lines) AS late_lines,
        SUM(pc.total_lines) AS total_lines
    FROM po_cycle pc
    JOIN suppliers s ON s.supplier_id = pc.supplier_id
    GROUP BY s.supplier_id, s.supplier_name
)
SELECT
    supplier_name,
    purchase_orders,
    avg_po_fulfillment_days,
    late_lines,
    total_lines,
    ROUND(100.0 * late_lines / NULLIF(total_lines, 0), 2) AS late_line_pct
FROM supplier_cycle
ORDER BY late_line_pct DESC, supplier_name;

-- 3. Conditional aggregation for supplier delivery success.
SELECT
    s.supplier_name,
    COUNT(DISTINCT po.po_id) AS total_purchase_orders,
    COUNT(CASE WHEN ol.actual_delivery_date IS NOT NULL THEN 1 END) AS delivered_lines,
    COUNT(CASE
        WHEN ol.actual_delivery_date <= ol.expected_delivery_date THEN 1
    END) AS on_time_lines,
    ROUND(
        100.0 * COUNT(CASE
            WHEN ol.actual_delivery_date <= ol.expected_delivery_date THEN 1
        END)
        / NULLIF(
            COUNT(CASE WHEN ol.actual_delivery_date IS NOT NULL THEN 1 END),
            0
        ),
        2
    ) AS delivery_success_rate_pct
FROM suppliers s
JOIN purchase_orders po ON po.supplier_id = s.supplier_id
JOIN order_lines ol ON ol.po_id = po.po_id
GROUP BY s.supplier_id, s.supplier_name
ORDER BY delivery_success_rate_pct DESC, s.supplier_name;

-- 4. Out-of-stock risk scoring using inventory thresholds and pending orders.
WITH pending AS (
    SELECT
        ol.item_id,
        SUM(ol.quantity) AS pending_quantity
    FROM order_lines ol
    JOIN purchase_orders po ON po.po_id = ol.po_id
    WHERE po.po_status <> 'CANCELLED'
      AND ol.actual_delivery_date IS NULL
    GROUP BY ol.item_id
),
risk AS (
    SELECT
        ii.item_code,
        ii.item_name,
        ii.current_stock,
        ii.reorder_level,
        COALESCE(p.pending_quantity, 0) AS pending_quantity,
        ii.current_stock + COALESCE(p.pending_quantity, 0) AS projected_available_stock,
        CASE
            WHEN ii.current_stock = 0 THEN 100
            WHEN ii.current_stock <= ii.reorder_level THEN 80
            WHEN ii.current_stock + COALESCE(p.pending_quantity, 0)
                 <= ii.reorder_level THEN 70
            WHEN ii.current_stock <= ii.reorder_level * 2 THEN 40
            ELSE 10
        END AS risk_score
    FROM inventory_items ii
    LEFT JOIN pending p ON p.item_id = ii.item_id
)
SELECT
    *,
    CASE
        WHEN risk_score >= 80 THEN 'CRITICAL'
        WHEN risk_score >= 60 THEN 'HIGH'
        WHEN risk_score >= 30 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS risk_band
FROM risk
ORDER BY risk_score DESC, item_code;

-- 5. Subquery-based item price variance against category averages.
SELECT
    ii.item_code,
    ii.item_name,
    c.category_name,
    ROUND(AVG(ol.unit_price), 2) AS item_avg_unit_price,
    ROUND((
        SELECT AVG(ol2.unit_price)
        FROM order_lines ol2
        JOIN inventory_items ii2 ON ii2.item_id = ol2.item_id
        WHERE ii2.category_id = ii.category_id
    ), 2) AS category_avg_unit_price,
    ROUND(
        AVG(ol.unit_price) - (
            SELECT AVG(ol3.unit_price)
            FROM order_lines ol3
            JOIN inventory_items ii3 ON ii3.item_id = ol3.item_id
            WHERE ii3.category_id = ii.category_id
        ),
        2
    ) AS variance_from_category_avg
FROM inventory_items ii
JOIN categories c ON c.category_id = ii.category_id
JOIN order_lines ol ON ol.item_id = ii.item_id
GROUP BY ii.item_id, ii.item_code, ii.item_name, ii.category_id, c.category_name
ORDER BY ABS(variance_from_category_avg) DESC, ii.item_code;
