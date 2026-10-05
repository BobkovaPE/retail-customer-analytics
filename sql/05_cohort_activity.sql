-- Удержание в конкретном календарном месяце возраста когорты.
WITH first_seen AS (
    SELECT customer_id, substr(MIN(order_date), 1, 7) AS cohort_month
    FROM customer_orders
    GROUP BY customer_id
), activity AS (
    SELECT DISTINCT f.cohort_month, substr(o.order_date, 1, 7) AS activity_month, o.customer_id
    FROM customer_orders AS o
    JOIN first_seen AS f ON o.customer_id = f.customer_id
)
SELECT cohort_month, activity_month,
    (CAST(substr(activity_month, 1, 4) AS INTEGER) - CAST(substr(cohort_month, 1, 4) AS INTEGER)) * 12
      + CAST(substr(activity_month, 6, 2) AS INTEGER) - CAST(substr(cohort_month, 6, 2) AS INTEGER) AS cohort_age,
    COUNT(*) AS active_customers
FROM activity
GROUP BY cohort_month, activity_month
ORDER BY cohort_month, activity_month;
