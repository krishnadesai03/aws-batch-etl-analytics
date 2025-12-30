CREATE SCHEMA IF NOT EXISTS dims;
-- NULL validation
SELECT
SUM(CASE WHEN invoice_no IS NULL THEN 1 ELSE 0 END) AS null_invoice,
SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product,
SUM(CASE WHEN date_id IS NULL THEN 1 ELSE 0 END) AS null_date
FROM fact_sales;

SELECT * FROM fact_sales WHERE invoice_no IS NULL;
SELECT * FROM fact_sales WHERE product_id IS NULL;
SELECT * FROM fact_sales WHERE date_id IS NULL;
-- all 0 as expected

-- Duplicate validation
SELECT invoice_no, product_id, date_id, COUNT(*)
FROM fact_sales
GROUP BY invoice_no, product_id, date_id
HAVING COUNT(*) > 1;

-- deleting duplicate rows
ROLLBACK;  -- if needed

BEGIN;

-- create a temp table with aggregated results for duplicate groups only
CREATE TEMP TABLE tmp_agg AS
SELECT
  invoice_no,
  product_id,
  date_id,
  SUM(quantity) AS quantity,
  SUM(revenue)  AS revenue,
  MAX(is_return)    AS is_return,
  MAX(is_free_item) AS is_free_item
FROM fact_sales
GROUP BY invoice_no, product_id, date_id
HAVING COUNT(*) > 1;

-- delete the existing duplicate rows (all rows for those groups)
DELETE FROM fact_sales f
USING tmp_agg t
WHERE f.invoice_no = t.invoice_no
  AND f.product_id = t.product_id
  AND f.date_id = t.date_id;

-- insert a single aggregated row per group back into the fact table
INSERT INTO fact_sales (invoice_no, product_id, date_id, quantity, revenue, is_return, is_free_item)
SELECT invoice_no, product_id, date_id, quantity, revenue, is_return, is_free_item
FROM tmp_agg;

COMMIT;
-- check for duplicates again
-- 0 rows returned as expected

-- Dimension uniqueness check
SELECT product_id, COUNT(*) FROM dims.dim_products
GROUP BY product_id HAVING COUNT(*) > 1;

SELECT customer_id, COUNT(*) FROM dims.dim_customers
GROUP BY customer_id HAVING COUNT(*) > 1;

SELECT date_id, COUNT(*) FROM dims.dim_date
GROUP BY date_id HAVING COUNT(*) > 1;

-- fixing duplicates issue

-- Handling duplicates in dim_customers
DROP TABLE IF EXISTS dim_customers;

CREATE TABLE dims.dim_customers AS
WITH ranked AS (
  SELECT
    customer_id,
    country,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY invoice_date DESC
    ) AS rn
  FROM staging.online_retail_cleaned
  WHERE customer_id IS NOT NULL
)
SELECT customer_id, country
FROM ranked
WHERE rn = 1;
-- check for duplicates again
-- 0 rows returned as expected

-- handling duplicates in dim_products
DROP TABLE IF EXISTS dims.dim_products;

CREATE TABLE dims.dim_products AS
WITH price_counts AS (
  SELECT
    stock_code AS product_id,
    description,
    unit_price,
    COUNT(*) AS cnt
  FROM staging.online_retail_cleaned
  WHERE unit_price IS NOT NULL
  GROUP BY stock_code, description, unit_price
),
ranked AS (
  SELECT
    product_id,
    description,
    unit_price,
    ROW_NUMBER() OVER (
      PARTITION BY product_id
      ORDER BY cnt DESC, unit_price ASC
    ) AS rn
  FROM price_counts
)
SELECT
  product_id,
  description,
  ROUND(unit_price::numeric, 2) AS unit_price
FROM ranked
WHERE rn = 1;
-- check for duplicates again
-- 0 rows returned as expected

-- handling duplicates in dim_date
DROP TABLE IF EXISTS dims.dim_date;

CREATE TABLE dims.dim_date AS
SELECT DISTINCT
  invoice_date::date AS date_id,
  EXTRACT(day   FROM invoice_date)::int AS day,
  EXTRACT(month FROM invoice_date)::int AS month,
  EXTRACT(year  FROM invoice_date)::int AS year
FROM staging.online_retail_cleaned;
-- check for duplicates again
-- 0 rows returned as expected

-- Validate referential integrity

-- fact -> product
SELECT COUNT(*) FROM fact_sales f
LEFT JOIN dims.dim_products p
  ON f.product_id = p.product_id
WHERE p.product_id IS NULL;

-- fact -> customer
SELECT COUNT(*) FROM fact_sales f
LEFT JOIN dims.dim_customers c
  ON f.customer_id = c.customer_id
WHERE f.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- fact -> date
SELECT COUNT(*) FROM fact_sales f
LEFT JOIN dims.dim_date d
  ON f.date_id = d.date_id
WHERE d.date_id IS NULL;

-- ALL return 0 as expected

-- Business logic validation

-- revenue sanity
SELECT
  SUM(revenue) AS total_revenue,
  SUM(CASE WHEN is_return = 1 THEN revenue ELSE 0 END) AS return_revenue,
  SUM(CASE WHEN is_free_item = 1 THEN revenue ELSE 0 END) AS free_item_revenue
FROM fact_sales;
-- Return revenue is negative as expected
-- Free item revenue is 0 as expected

-- returns behaviour
SELECT COUNT(*) AS return_rows, AVG(quantity) AS avg_return_qty
FROM fact_sales WHERE is_return = 1;

-- country-level sanity
SELECT c.country, SUM(f.revenue) AS revenue
FROM fact_sales f JOIN dims.dim_customers c
  ON f.customer_id = c.customer_id
GROUP BY c.country
ORDER BY revenue DESC
LIMIT 10;
