-- Один счёт = один заказ. Данные уже прошли проверки согласованности.
-- Расхождения времени до минуты внутри одного дня допустимы.
DROP VIEW IF EXISTS customer_orders;
DROP TABLE IF EXISTS orders;

CREATE TABLE orders AS
SELECT
    invoice_no,
    MIN(invoice_date) AS order_date,
    MAX(invoice_date) AS last_line_date,
    MIN(customer_id) AS customer_id,
    MIN(country) AS country,
    COUNT(*) AS line_count,
    COUNT(DISTINCT stock_code) AS distinct_products,
    SUM(quantity) AS units,
    SUM(line_amount_gbp) AS gross_sales_gbp,
    SUM(is_exact_duplicate) AS duplicate_lines,
    COUNT(DISTINCT invoice_date) AS timestamp_count
FROM purchase_lines
GROUP BY invoice_no;

CREATE UNIQUE INDEX idx_orders_invoice ON orders(invoice_no);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);

CREATE VIEW customer_orders AS
SELECT * FROM orders WHERE customer_id IS NOT NULL;
