# Day 3 – Staging Layer Analysis & Results

## Objective
The objective of Day 3 was to build a **cleaned staging table** from raw retail transaction data by:
- Preserving original source values
- Removing duplicate records
- Adding business-context flags
- Documenting data quality characteristics for downstream modeling

This staging layer serves as the foundation for dimensional modeling and fact table creation.

---

## Staging Table
**Table name:** `staging.online_retail_cleaned`  
**Source:** `raw.online_retail`

The staging table applies **light preprocessing** and **business rule annotation**, without altering the original numeric values.

---

## Transformations Applied

### 1. Business Flags
To retain original values while making business scenarios explicit:

- **`is_return`**
  - Created to flag return transactions
  - Logic: `quantity < 0`
  - Original negative quantities are preserved

- **`is_free_item`**
  - Created to flag free or promotional items
  - Logic: `unit_price = 0`
  - Original unit price values are preserved

This approach allows downstream analytics to decide how returns and free items should be treated.

---

### 2. Deduplication
Duplicate rows were removed based on the business key:

- invoice_no
- stock_code
- invoice_date
- customer_id


Deduplication was implemented using a window function (`ROW_NUMBER`) and keeping the first occurrence of each duplicate group.

---

### 3. Light Data Cleaning
- Trimmed leading and trailing whitespace from string columns
- Converted empty descriptions to `NULL`
- Preserved all original numeric values (`quantity`, `unit_price`)
- No imputation or correction was performed at the staging level

---

## Results Summary

### Row Counts
| Layer   | Rows   |
|--------|--------|
| Raw    | 541,909 |
| Staging | 531,232 |

**Duplicates removed:** `10,677`

---

### NULL Value Analysis
| Column        | NULL Count |
|--------------|------------|
| `customer_id` | 135,080 |
| `description` | 1,454 |

**Notes:**
- Missing `customer_id` values are expected (guest checkouts or incomplete customer records)
- Missing descriptions are minimal and do not affect core transactional metrics

---

### Business Flag Statistics
| Flag | Count |
|-----|-------|
| `is_return = TRUE` | 10,475 |
| `is_free_item = TRUE` | 2,495 |

**Insights:**
- Returns represent a non-trivial portion of transactions and must be explicitly handled in fact tables
- Free items exist and should not be excluded blindly without business context

---

## Design Decisions & Rationale

- **Staging does not modify numeric values**
  - Negative quantities and zero prices are preserved
  - Business meaning is captured via flags instead of overwriting data

- **NULL values are allowed in staging**
  - Staging reflects data reality, not business assumptions
  - Imputation and filtering belong to analytics/mart layers

- **Raw vs Staging separation**
  - Raw layer preserves source-of-truth
  - Staging layer standardizes structure and annotates business logic

---

## Readiness for Next Step
The staging table is now:
- Deduplicated
- Business-aware
- Auditable
- Safe for dimensional modeling

**Next step:** Build dimension tables (`dim_customers`, `dim_products`, `dim_date`) and the `fact_sales` table.

---
