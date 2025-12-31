from sqlalchemy import create_engine
import os

DB_URL = os.getenv("DATABASE_URL", "postgresql://postgres:Shivshiv19$#@localhost:5432/retail_dw")

def get_engine():
    return create_engine(DB_URL, client_encoding='utf8')

def read_table(table_name, schema='raw'):
    import pandas as pd
    engine = get_engine()
    return pd.read_sql_table(table_name, schema=schema, con=engine)
