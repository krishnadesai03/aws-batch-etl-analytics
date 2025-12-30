-- Index on date for time-range filters
CREATE INDEX IF NOT EXISTS idx_fact_date ON fact_sales (date_id);

-- Index on product for product-level aggregations
CREATE INDEX IF NOT EXISTS idx_fact_product ON fact_sales (product_id);

-- Index on customer for customer aggregates
CREATE INDEX IF NOT EXISTS idx_fact_customer ON fact_sales (customer_id);

-- Composite index if queries often filter by date and then group by product
CREATE INDEX IF NOT EXISTS idx_fact_date_product ON fact_sales (date_id, product_id);

VACUUM (VERBOSE, ANALYZE) fact_sales;
ANALYZE fact_sales;