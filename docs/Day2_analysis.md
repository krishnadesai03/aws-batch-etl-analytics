# Day 2 – Raw Data Ingestion & Validation

## Objective
The objective of Day 2 was to ingest the raw retail dataset into PostgreSQL while **preserving source data integrity**.

This step establishes the **raw layer**, which serves as the immutable source-of-truth for all downstream processing.

---

## Raw Layer Design

### Database
- **Database**: PostgreSQL
- **Schema**: `raw`
- **Table**: `raw.online_retail`

The raw schema is intentionally kept simple and mirrors the source data structure.

---

## Ingestion Process
- A Python ingestion script was created using:
  - `pandas`
  - `sqlalchemy`
- The dataset was loaded directly from the Excel file into PostgreSQL
- No transformations or data corrections were applied at this stage

This ensures that the raw layer accurately reflects the original dataset.

---

## Raw Table Schema

| Column        | Data Type |
|--------------|----------|
| invoice_no   | TEXT |
| stock_code   | TEXT |
| description  | TEXT |
| quantity     | BIGINT |
| invoice_date | TIMESTAMP |
| unit_price   | DOUBLE PRECISION |
| customer_id  | DOUBLE PRECISION |
| country      | TEXT |

---

## Initial Data Validation

### Row Count
- **Raw rows loaded**: 541,909

### Observed Data Characteristics
- `customer_id` contains NULL values
- `quantity` contains negative values (returns)
- `unit_price` contains zero values (free items)
- `description` contains empty or NULL values

These issues were intentionally **not fixed** in the raw layer.

---

## Design Decisions

- **Raw data is preserved as-is**
  - No filtering
  - No deduplication
  - No type normalization
- Data quality issues are documented and addressed in later layers
- Raw layer enables auditing and reproducibility

---

## Validation Queries Used
```sql
SELECT COUNT(*) FROM raw.online_retail;

SELECT COUNT(*) FROM raw.online_retail WHERE customer_id IS NULL;
SELECT COUNT(*) FROM raw.online_retail WHERE quantity < 0;
SELECT COUNT(*) FROM raw.online_retail WHERE unit_price = 0;
