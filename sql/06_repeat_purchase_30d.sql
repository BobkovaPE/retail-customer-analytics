-- Строго более поздний заказ, не позднее first_order + 30 суток.
-- :cutoff — исключённая правая граница наблюдения, 2011-12-01 00:00:00.
WITH first_seen AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM customer_orders
    GROUP BY customer_id
), following AS (
    SELECT f.customer_id, f.first_order_date, MIN(o.order_date) AS next_order_date
    FROM first_seen AS f
    LEFT JOIN customer_orders AS o
      ON o.customer_id = f.customer_id AND o.order_date > f.first_order_date
    GROUP BY f.customer_id, f.first_order_date
), eligible AS (
    SELECT *, substr(first_order_date, 1, 7) AS cohort_month,
        CASE WHEN datetime(first_order_date, '+30 days') < :cutoff THEN 1 ELSE 0 END AS eligible_30d
    FROM following
)
SELECT *,
    CASE WHEN eligible_30d = 0 THEN NULL
         WHEN next_order_date <= datetime(first_order_date, '+30 days') THEN 1
         ELSE 0 END AS repeat_within_30d
FROM eligible
ORDER BY customer_id;
