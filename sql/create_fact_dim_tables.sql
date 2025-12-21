-- Create fact and dim tables
DROP TABLE IF EXISTS dim_products;

CREATE TABLE dim_products AS
SELECT DISTINCT stock_code AS product_id, description, unit_price
FROM staging.online_retail_cleaned
WHERE stock_code IS NOT NULL;

DROP TABLE IF EXISTS dim_customers;

CREATE TABLE dim_customers AS
SELECT DISTINCT customer_id, country
FROM staging.online_retail_cleaned
WHERE customer_id IS NOT NULL;

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date AS
SELECT invoice_date::DATE AS date_id,
    EXTRACT(DAY FROM invoice_date) AS day,
    EXTRACT(MONTH FROM invoice_date) AS month,
    EXTRACT(YEAR FROM invoice_date) AS year
FROM staging.online_retail_cleaned
WHERE invoice_date IS NOT NULL;

DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales As
SELECT DISTINCT s.invoice_no, s.stock_code AS product_id, s.customer_id, s.invoice_date::DATE AS date_id, s.quantity, s.unit_price, (s.quantity * s.unit_price) AS revenue, s.is_return, s.is_free_item
FROM staging.online_retail_cleaned s;

-- validate the model

-- row counts
SELECT COUNT(*) FROM fact_sales;

-- check revenue column
SELECT MIN(revenue), MAX(revenue), SUM(revenue)
FROM fact_sales;

-- join sanity
SELECT COUNT(*)
FROM fact_sales f
LEFT JOIN dim_products p ON f.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Create indexes
CREATE INDEX idx_fact_date ON fact_sales (date_id);
CREATE INDEX idx_fact_customer ON fact_sales (customer_id);
CREATE INDEX idx_fact_product ON fact_sales (product_id);
