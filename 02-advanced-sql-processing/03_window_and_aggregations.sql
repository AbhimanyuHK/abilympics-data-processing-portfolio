-- 1. Top-N items per category using DENSE_RANK and ROW_NUMBER.
WITH item_spend AS (
    SELECT
        c.category_name,
        ii.item_code,
        ii.item_name,
        ROUND(SUM(ol.quantity * ol.unit_price), 2) AS total_spend
    FROM categories c
    JOIN inventory_items ii ON ii.category_id = c.category_id
    JOIN order_lines ol ON ol.item_id = ii.item_id
    GROUP BY c.category_name, ii.item_id, ii.item_code, ii.item_name
),
ranked AS (
    SELECT
        item_spend.*,
        DENSE_RANK() OVER (
            PARTITION BY category_name
            ORDER BY total_spend DESC
        ) AS spend_rank,
        ROW_NUMBER() OVER (
            PARTITION BY category_name
            ORDER BY total_spend DESC, item_code
        ) AS row_number_in_category
    FROM item_spend
)
SELECT
    category_name,
    item_code,
    item_name,
    total_spend,
    spend_rank,
    row_number_in_category
FROM ranked
WHERE spend_rank <= 3
ORDER BY category_name, spend_rank, row_number_in_category;

-- 2. Month-over-month variance and trend using LAG and LEAD.
WITH monthly_spend AS (
    SELECT
        strftime('%Y-%m', po.order_date) AS order_month,
        ROUND(SUM(ol.quantity * ol.unit_price), 2) AS monthly_spend
    FROM purchase_orders po
    JOIN order_lines ol ON ol.po_id = po.po_id
    GROUP BY strftime('%Y-%m', po.order_date)
)
SELECT
    order_month,
    monthly_spend,
    LAG(monthly_spend) OVER (ORDER BY order_month) AS previous_month_spend,
    ROUND(
        monthly_spend - LAG(monthly_spend) OVER (ORDER BY order_month),
        2
    ) AS mom_variance,
    ROUND(
        100.0 * (
            monthly_spend - LAG(monthly_spend) OVER (ORDER BY order_month)
        )
        / NULLIF(
            LAG(monthly_spend) OVER (ORDER BY order_month),
            0
        ),
        2
    ) AS mom_variance_pct,
    LEAD(monthly_spend) OVER (ORDER BY order_month) AS next_month_spend,
    CASE
        WHEN LAG(monthly_spend) OVER (ORDER BY order_month) IS NULL THEN 'BASELINE'
        WHEN monthly_spend > LAG(monthly_spend) OVER (ORDER BY order_month) THEN 'UPTREND'
        WHEN monthly_spend < LAG(monthly_spend) OVER (ORDER BY order_month) THEN 'DOWNTREND'
        ELSE 'FLAT'
    END AS trend
FROM monthly_spend
ORDER BY order_month;

-- 3. Cumulative and three-PO rolling spend by supplier.
WITH supplier_orders AS (
    SELECT
        s.supplier_name,
        po.order_date,
        po.po_number,
        ROUND(SUM(ol.quantity * ol.unit_price), 2) AS po_spend
    FROM suppliers s
    JOIN purchase_orders po ON po.supplier_id = s.supplier_id
    JOIN order_lines ol ON ol.po_id = po.po_id
    GROUP BY s.supplier_id, s.supplier_name, po.po_id, po.order_date, po.po_number
)
SELECT
    supplier_name,
    order_date,
    po_number,
    po_spend,
    ROUND(
        SUM(po_spend) OVER (
            PARTITION BY supplier_name
            ORDER BY order_date, po_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_supplier_spend,
    ROUND(
        SUM(po_spend) OVER (
            PARTITION BY supplier_name
            ORDER BY order_date, po_number
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3_po_spend
FROM supplier_orders
ORDER BY supplier_name, order_date, po_number;

-- 4. Quartile categorization of supplier lead times using NTILE.
WITH supplier_lead_times AS (
    SELECT
        s.supplier_name,
        ol.order_line_id,
        CAST(
            julianday(ol.actual_delivery_date)
            - julianday(po.order_date)
            AS INTEGER
        ) AS lead_time_days
    FROM suppliers s
    JOIN purchase_orders po ON po.supplier_id = s.supplier_id
    JOIN order_lines ol ON ol.po_id = po.po_id
    WHERE ol.actual_delivery_date IS NOT NULL
)
SELECT
    supplier_name,
    order_line_id,
    lead_time_days,
    NTILE(4) OVER (
        ORDER BY lead_time_days, order_line_id
    ) AS lead_time_quartile
FROM supplier_lead_times
ORDER BY lead_time_days, order_line_id;
