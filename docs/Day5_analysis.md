# Day 5 — Data Quality Validation & Debugging

## 🎯 Objective
Validate the analytical integrity of the star schema by enforcing data quality rules, verifying business logic, and resolving modeling and duplication issues discovered during validation.

---

## 🧪 Data Quality Checks Performed

### Fact Table (`fact_sales`)
The following checks were applied to ensure analytical correctness:

- `invoice_no`, `product_id`, and `date_id` must not be NULL
- Fact table grain enforced as **one row per invoice × product × date**
- Revenue verified as `quantity × unit_price`
- Negative revenue allowed for returns
- Zero revenue allowed for free items

### Dimension Tables
- `dim_products.product_id` must be unique
- `dim_customers.customer_id` must be unique
- `dim_date.date_id` must be unique

All uniqueness and null checks were validated using SQL aggregation and join tests.

---

## 🔗 Referential Integrity Validation

The following joins were validated:

- `fact_sales → dim_products`
- `fact_sales → dim_customers` (excluding NULL customer IDs)
- `fact_sales → dim_date`

All foreign key relationships were verified to resolve correctly without introducing orphaned fact records.

---

## 🧠 Business Logic Validation

### Revenue Sanity Checks
- Total revenue aggregation verified
- Return transactions correctly produced negative revenue
- Free items correctly resulted in zero revenue

### Behavioral Validation
- Return quantities were validated for expected negative values
- Country-level revenue aggregation produced realistic results

These checks confirmed that the fact table is safe for downstream analytics.

---

## 🛠️ Debugging: Fact Table Duplication Issue

### Issue
During validation of the `fact_sales` table, **duplicate rows were detected for the intended grain**  
(**invoice × product × date**), violating the star schema design.

While attempting to fix this, several PostgreSQL issues were encountered:
- Incorrect use of `BOOL_OR()` on integer flag columns (`is_return`, `is_free_item`)
- Aborted transactions caused by failed statements not being rolled back
- References to non-existent columns during reinsertion
- Incorrect reuse of CTEs across multiple SQL statements

### Resolution
The issue was resolved through the following steps:
- Rolled back aborted transactions before continuing
- Replaced `BOOL_OR()` with `MAX()` to correctly aggregate binary flags
- Aligned INSERT statements exactly with the `fact_sales` table schema
- Materialized aggregated duplicate rows into a **temporary table**
- Safely deleted duplicate rows from `fact_sales`
- Reinserted a **single consolidated row per grain**

This approach restored fact table integrity **without data loss** and preserved accurate metrics.

---


## ✅ Outcome
- Fact table grain correctly enforced
- Duplicate records eliminated safely
- All dimension tables validated for uniqueness
- Business logic confirmed for returns and free items
- Warehouse is now analytics-safe and production-ready
