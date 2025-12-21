# Day 4 – Dimensional Modeling & Fact Table Creation

## Objective
The objective of Day 4 was to model the cleaned staging data into **analytics-ready dimension and fact tables** following a star schema design.

---

## Dimension Tables Created

### `dim_customers`
- customer_id
- country

Built from distinct customer records in the staging layer.  
NULL customer IDs were retained to reflect real-world guest transactions.

### `dim_products`
- stock_code (product_id)
- description

Represents unique products and their attributes.

### `dim_date`
- date_id
- calendar attributes (day, month, year)

Derived from transaction dates to support time-based analysis.

---

## Fact Table Created

### `fact_sales`
Grain: **one row per invoice × product × date**

Columns include:
- invoice_no
- product_id
- customer_id
- date_id
- quantity
- revenue
- is_return
- is_free_item

### Revenue Calculation
```text
revenue = quantity × unit_price
