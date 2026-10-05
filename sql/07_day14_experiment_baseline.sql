-- Исторический аналог отбора на 14-е сутки; это не данные эксперимента.
-- :cutoff = '2011-12-01 00:00:00'. История только из customer_orders.
WITH first_purchase AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM customer_orders
    GROUP BY customer_id
), anchors AS (
    SELECT customer_id, first_order_date,
           datetime(first_order_date, '+14 days') AS anchor_date,
           datetime(first_order_date, '+44 days') AS observation_end
    FROM first_purchase
), history AS (
    SELECT a.customer_id, a.first_order_date, a.anchor_date, a.observation_end,
           SUM(CASE WHEN o.order_date <= a.anchor_date THEN 1 ELSE 0 END)
               AS invoices_at_anchor,
           MIN(CASE WHEN o.order_date > a.anchor_date THEN o.order_date END)
               AS next_order_after_anchor
    FROM anchors a
    JOIN customer_orders o ON o.customer_id = a.customer_id
    GROUP BY a.customer_id, a.first_order_date, a.anchor_date, a.observation_end
)
SELECT *,
       CASE WHEN first_order_date >= '2011-01-01 00:00:00'
                 AND anchor_date < :cutoff AND invoices_at_anchor = 1
            THEN 1 ELSE 0 END AS eligible_at_day14,
       CASE WHEN observation_end < :cutoff THEN 1 ELSE 0 END AS full_followup,
       CASE WHEN observation_end >= :cutoff THEN NULL
            WHEN next_order_after_anchor <= observation_end THEN 1
            ELSE 0 END AS repeat_in_next_30d
FROM history
ORDER BY customer_id;
