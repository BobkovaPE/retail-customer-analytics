-- Категория задаётся по месяцу первого наблюдаемого заказа клиента.
-- Все покупки клиента в первом месяце входят в first_month_sales_gbp.
-- Эти показатели не являются retention или числом первых заказов.
WITH first_seen AS (
    SELECT customer_id, substr(MIN(order_date), 1, 7) AS first_observed_month
    FROM customer_orders
    GROUP BY customer_id
), customer_month AS (
    SELECT
        o.customer_id,
        substr(o.order_date, 1, 7) AS month,
        f.first_observed_month,
        COUNT(*) AS orders,
        SUM(o.gross_sales_gbp) AS gross_sales_gbp
    FROM customer_orders AS o
    JOIN first_seen AS f ON o.customer_id = f.customer_id
    GROUP BY o.customer_id, substr(o.order_date, 1, 7), f.first_observed_month
)
SELECT
    month,
    COUNT(*) AS active_identified_customers,
    SUM(CASE WHEN month = first_observed_month THEN 1 ELSE 0 END) AS first_observed_customers,
    SUM(CASE WHEN month > first_observed_month THEN 1 ELSE 0 END) AS previously_observed_customers,
    SUM(orders) AS identified_orders,
    SUM(gross_sales_gbp) AS identified_sales_gbp,
    SUM(CASE WHEN month = first_observed_month THEN gross_sales_gbp ELSE 0 END) AS first_month_sales_gbp,
    SUM(CASE WHEN month > first_observed_month THEN gross_sales_gbp ELSE 0 END) AS previous_months_customers_sales_gbp
FROM customer_month
GROUP BY month
ORDER BY month;
