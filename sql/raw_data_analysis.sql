CREATE TABLE raw.online_retail (
	InvoiceNo VARCHAR,
	StockCode VARCHAR,
	Description TEXT,
	Quantity INTEGER,
	InvoiceDate TIMESTAMP,
	UnitPrice NUMERIC,
	CustomerID INTEGER,
	Country VARCHAR
);

SELECT COUNT(*) AS db_rowcount FROM raw.online_retail;

-- Show columns + data types in table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'online_retail'
ORDER BY ordinal_position;

SELECT
  COUNT(*) AS total_rows,
  COUNT(customer_id) AS non_null_customerid,
  COUNT(description) AS non_null_description,
  SUM(CASE WHEN invoice_date IS NULL THEN 1 ELSE 0 END) AS null_invoice_date,
  SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
  SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_unit_price
FROM raw.online_retail;

SELECT
  SUM(CASE WHEN quantity < 0 THEN 1 ELSE 0 END) AS return_rows,
  MIN(quantity) AS min_quantity,
  MAX(quantity) AS max_quantity
FROM raw.online_retail;

SELECT
  SUM(CASE WHEN unit_price <= 0 THEN 1 ELSE 0 END) AS zero_or_negative_price,
  MIN(unit_price) AS min_price,
  MAX(unit_price) AS max_price
FROM raw.online_retail;

-- Full-row duplicates
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT invoice_no || '-' || stock_code || '-' || invoice_date::text || '-' || coalesce(customer_id::text,'NULL')) AS distinct_keys
FROM raw.online_retail;
-- Or explicit duplicate rows list
SELECT invoice_no, stock_code, invoice_date, customer_id, COUNT(*) as cnt
FROM raw.online_retail
GROUP BY invoice_no, stock_code, invoice_date, customer_id
HAVING COUNT(*) > 1
LIMIT 20;

