-- Baseline: pick 2–3 representative queries and measure

-- Q1: monthly revenue by product (heavy group-by + join)
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT p.product_id, SUM(f.revenue) AS total_revenue
FROM fact_sales f
JOIN dim_products p ON f.product_id = p.product_id
WHERE f.date_id BETWEEN '2010-01-01' AND '2011-12-31'
GROUP BY p.product_id
ORDER BY total_revenue DESC
LIMIT 50;

-- Q2: customer lifetime revenue
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT f.customer_id, SUM(f.revenue) AS lifetime_revenue
FROM fact_sales f
GROUP BY f.customer_id
ORDER BY lifetime_revenue DESC
LIMIT 50;

-- Q3: country-level revenue over time (join to customers + date)
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT d.year, c.country, SUM(f.revenue) AS revenue
FROM fact_sales f
JOIN dims.dim_date d ON f.date_id = d.date_id
JOIN dims.dim_customers c ON f.customer_id = c.customer_id
GROUP BY d.year, c.country
ORDER BY d.year, revenue DESC
LIMIT 50;

-- Inspect current table sizes & bloat
-- size of tables
SELECT relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- row estimates
SELECT schemaname, relname AS table_name, n_live_tup
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC LIMIT 10;