# Day 1 – Project Setup & Data Modeling

## Objective
The objective of Day 1 was to define the **problem scope**, understand the dataset, and design a **scalable data model** before writing any ETL code.

This day focused on *thinking like a data engineer*: understanding business requirements, defining grain, and designing the warehouse structure upfront.

---

## Dataset Selection
- **Dataset**: Online Retail Transactions
- **Source**: UCI Machine Learning Repository
- **Domain**: E-commerce
- **Records**: ~541K transactions
- **Format**: Excel / CSV

The dataset represents real-world retail transactions and includes common data quality challenges such as missing customer identifiers, returns, and free items.

---

## Business Use Case
The pipeline is designed to support common retail analytics questions such as:
- Total revenue over time
- Product performance and sales trends
- Customer purchasing behavior
- Impact of returns and free items on revenue

---

## Data Modeling Approach

### Grain Definition
The grain of the fact table is defined as:

> **One row per invoice × product × date**

This grain supports flexible aggregation across products, customers, and time.

---

### Star Schema Design

#### Fact Table
**`fact_sales`**
- invoice_no
- product_id
- customer_id
- date_id
- quantity
- revenue
- is_return
- is_free_item

#### Dimension Tables
- **`dim_products`**
  - product_id
  - description
  - price attributes

- **`dim_customers`**
  - customer_id
  - country

- **`dim_date`**
  - date_id
  - day, month, year, etc.

This star schema is optimized for analytical queries and reporting.

---

## Architecture Design
The initial architecture follows a batch ETL pattern:

![alt text](image.png)