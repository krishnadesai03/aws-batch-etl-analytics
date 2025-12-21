CREATE SCHEMA IF NOT EXISTS staging;

-- check row count
SELECT COUNT(*) FROM raw.online_retail;

-- check datatypes
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'raw' AND table_name = 'online_retail';

-- SELECT invoice_date, pg_typeof(invoice_date) FROM raw.online_retail LIMIT 10;

-- Negative values in quantity, unit price
SELECT MIN(quantity), MAX(quantity) FROM raw.online_retail;
SELECT MIN(unit_price), MAX(unit_price) FROM raw.online_retail;

-- Number of rows where quantity is -ve
SELECT COUNT(*) FROM raw.online_retail WHERE quantity < 0;

-- Number of rows where unit price is -ve or zero
SELECT COUNT(*) FROM raw.online_retail WHERE unit_price <= 0;

-- Number of rows where customer id is null
SELECT COUNT(*) FROM raw.online_retail WHERE customer_id IS NULL;

-- 
-- sql/2_create_staging_online_retail.sql
DROP TABLE IF EXISTS staging.online_retail_cleaned;

CREATE TABLE staging.online_retail_cleaned AS
WITH raw_prep AS (
    SELECT
        TRIM(invoice_no)                       AS invoice_no,
        TRIM(stock_code)                       AS stock_code,
        NULLIF(TRIM(description), '')::TEXT    AS description,
        quantity,
        unit_price,
        invoice_date::timestamp                AS invoice_date,
        customer_id,
        TRIM(country)                          AS country
    FROM raw.online_retail
),
flagged AS (
    SELECT
        *,
        CASE WHEN quantity < 0 THEN 1 ELSE 0 END AS is_return,
        CASE WHEN unit_price = 0 THEN 1 ELSE 0 END AS is_free_item
    FROM raw_prep
),
deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY invoice_no, stock_code, invoice_date, customer_id
            ORDER BY invoice_no
        ) AS rn
    FROM flagged
)
SELECT
    invoice_no,
    stock_code,
    description,
    quantity,
    unit_price,
    invoice_date,
    customer_id,
    country,
    is_return,
    is_free_item
FROM deduped
WHERE rn = 1;

SELECT * 
FROM staging.online_retail_cleaned
LIMIT 20;

SELECT * 
FROM staging.online_retail_cleaned
WHERE quantity < 0
LIMIT 10;

-- Compare row count of raw vs staging
SELECT COUNT(*) FROM staging.online_retail_cleaned; --531232
SELECT COUNT(*) FROM raw.online_retail; --541909

-- check table structure
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name   = 'online_retail_cleaned'
ORDER BY ordinal_position;

-- check flagged rows
SELECT
    COUNT(*) FILTER (WHERE is_return = 1) AS return_rows,
    COUNT(*) FILTER (WHERE is_free_item = 1) AS free_items
FROM staging.online_retail_cleaned;

-- check absense of duplicates
SELECT
    invoice_no,
    stock_code,
    invoice_date,
    customer_id,
    COUNT(*)
FROM staging.online_retail_cleaned
GROUP BY 1,2,3,4
HAVING COUNT(*) > 1;

-- check min-max rows in quantity, unit price
SELECT MIN(quantity), MAX(quantity), MIN(unit_price), MAX(unit_price)
FROM staging.online_retail_cleaned;

CREATE INDEX idx_stg_invoice_date ON staging.online_retail_cleaned (invoice_date);
CREATE INDEX idx_stg_customer ON staging.online_retail_cleaned (customer_id);



