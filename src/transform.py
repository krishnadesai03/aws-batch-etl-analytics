from .db import get_engine
import sqlalchemy

STAGING_SQL = open("sql/create_staging_online_retail.sql").read()

def create_staging():
    engine = get_engine()
    with engine.begin() as conn:
        conn.execute(sqlalchemy.text(STAGING_SQL))
    return True

if __name__ == "__main__":
    create_staging()
    print("staging.online_retail_cleaned created")