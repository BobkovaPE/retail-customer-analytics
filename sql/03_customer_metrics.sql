-- Одна строка на известный CustomerID. Только наблюдаемое окно.
SELECT
    customer_id,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    substr(MIN(order_date), 1, 7) AS first_observed_month,
    COUNT(*) AS orders,
    COUNT(DISTINCT substr(order_date, 1, 7)) AS active_months,
    SUM(gross_sales_gbp) AS gross_sales_gbp,
    SUM(units) AS units,
    1.0 * SUM(gross_sales_gbp) / COUNT(*) AS aov_gbp
FROM customer_orders
GROUP BY customer_id
ORDER BY customer_id;
