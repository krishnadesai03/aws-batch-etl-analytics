# Performance Report — Day 6

## Summary
I measured baseline performance for representative analytical queries (aggregations, joins, and time-range filters) using `EXPLAIN (ANALYZE, BUFFERS)` and verified execution plans. Given the current dataset size (~500k rows) query runtime is acceptable and additional heavy optimizations (partitioning, materialized views) are not justified — doing so would be premature optimization.

## Baseline queries tested
- Monthly product revenue (join fact_sales → dim_products, group by product)
- Customer lifetime revenue (group by customer)
- Country-year revenue (joins: fact_sales → dim_date → dim_customers)

*(Saved EXPLAIN outputs placed in `sql/q1-results.csv` `sql/q2-results.csv` and `sql/q3-results.csv`)*

## Actions taken
- Created light-weight indexes to support common analytics patterns:
  - `CREATE INDEX IF NOT EXISTS idx_fact_date ON fact_sales (date_id);`
  - `CREATE INDEX IF NOT EXISTS idx_fact_product ON fact_sales (product_id);`
  - `CREATE INDEX IF NOT EXISTS idx_fact_customer ON fact_sales (customer_id);`

- Ran `VACUUM ANALYZE` to refresh planner statistics.

## Findings & Rationale
- Execution times are low enough for an interactive BI workflow; planner chooses efficient plans.
- Indexes added produced marginal improvements for the tested queries and are kept because they are low-cost and useful for typical analytics patterns.
- Partitioning, materialized views, and aggressive tuning were **not** implemented because:
  - Dataset size does not yet justify the operational complexity.
  - The measured benefit was negligible relative to added maintenance cost.

## Recommendations (if data grows)
- Revisit partitioning by `date_id` once `fact_sales` grows into the multi-million row regime or query latency becomes a problem.
- Create materialized views for frequently-run heavy aggregations (monthly product revenue) if query frequency increases.
- Consider read replica / columnar warehouse (e.g., Redshift / Snowflake / BigQuery) for production BI scale.

## Files / Artifacts
- `sql/q1-results.csv` — raw EXPLAIN outputs captured during benchmarking
- `sql/benchmark_queries.sql` — Queries that resemble expected analytical workloads (time series, top products, customer aggregates) (kept/committed)
- `sql/indexes.sql` — index creation statements (kept/committed)
