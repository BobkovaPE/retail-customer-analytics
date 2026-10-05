-- Все товарные заказы основного окна, включая неизвестный CustomerID.
-- gross_sales_gbp — положительные товарные продажи ДО вычета отмен.
WITH monthly AS (
    SELECT
        substr(order_date, 1, 7) AS month,
        COUNT(*) AS orders,
        SUM(gross_sales_gbp) AS gross_sales_gbp,
        SUM(units) AS units,
        1.0 * SUM(gross_sales_gbp) / COUNT(*) AS aov_gbp,
        1.0 * SUM(units) / COUNT(*) AS units_per_order,
        COUNT(DISTINCT customer_id) AS active_identified_customers,
        SUM(CASE WHEN customer_id IS NOT NULL THEN 1 ELSE 0 END) AS identified_orders,
        SUM(CASE WHEN customer_id IS NOT NULL THEN gross_sales_gbp ELSE 0 END) AS identified_sales_gbp
    FROM orders
    GROUP BY substr(order_date, 1, 7)
), previous AS (
    SELECT *,
        LAG(gross_sales_gbp) OVER (ORDER BY month) AS previous_sales_gbp,
        LAG(orders) OVER (ORDER BY month) AS previous_orders,
        LAG(aov_gbp) OVER (ORDER BY month) AS previous_aov_gbp
    FROM monthly
)
SELECT *,
    100.0 * (gross_sales_gbp / NULLIF(previous_sales_gbp, 0) - 1) AS sales_mom_pct,
    100.0 * (1.0 * orders / NULLIF(previous_orders, 0) - 1) AS orders_mom_pct,
    100.0 * (aov_gbp / NULLIF(previous_aov_gbp, 0) - 1) AS aov_mom_pct,
    100.0 * identified_orders / orders AS identified_orders_pct,
    100.0 * identified_sales_gbp / gross_sales_gbp AS identified_sales_pct
FROM previous
ORDER BY month;
