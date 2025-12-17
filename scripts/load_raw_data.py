import pandas as pd
from sqlalchemy import create_engine

# Load dataset
df = pd.read_excel("data/raw/online_retail.xlsx")

# Rename columns for consistency
df.columns = [
    "invoice_no", "stock_code", "description", "quantity",
    "invoice_date", "unit_price", "customer_id", "country"
]

# Create DB connection
engine = create_engine(
    "postgresql://postgres:Shivshiv19$#@localhost:5432/retail_dw"
)

# Load data into Postgres
df.to_sql(
    "online_retail",
    engine,
    schema="raw",
    if_exists="replace",
    index=False
)

print("Raw data loaded successfully.")
