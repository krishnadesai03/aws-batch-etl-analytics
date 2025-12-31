import io
import os
import logging
import pandas as pd
from .db import get_engine

# -----------------------
# Logging setup
# -----------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)
logger = logging.getLogger(__name__)


def load_excel_to_raw(
    path="data/raw/online_retail.xlsx",
    table="online_retail",
    schema="raw",
    if_exists="replace"
):
    if not os.path.exists(path):
        raise FileNotFoundError(f"Data file not found: {path}")

    logger.info("Reading Excel file: %s", path)
    df = pd.read_excel(path)

    # Preserve original column mapping
    df.columns = [
        "invoice_no",
        "stock_code",
        "description",
        "quantity",
        "invoice_date",
        "unit_price",
        "customer_id",
        "country"
    ]

    engine = get_engine()
    fq_table = f"{schema}.{table}"

    # -----------------------
    # Ensure target table exists
    # -----------------------
    create_table_sql = f"""
    CREATE TABLE IF NOT EXISTS {fq_table} (
        invoice_no TEXT,
        stock_code TEXT,
        description TEXT,
        quantity BIGINT,
        invoice_date TIMESTAMP,
        unit_price DOUBLE PRECISION,
        customer_id DOUBLE PRECISION,
        country TEXT
    );
    """

    try:
        with engine.begin() as conn:
            if if_exists == "replace":
                conn.execute(f"DROP TABLE IF EXISTS {fq_table};")
            conn.execute(create_table_sql)
    except Exception:
        logger.exception("Failed to ensure target table exists")
        raise

    # -----------------------
    # COPY load (robust path)
    # -----------------------
    raw_conn = None
    try:
        buffer = io.StringIO()
        df.to_csv(
            buffer,
            index=False,
            header=True,
            date_format="%Y-%m-%d %H:%M:%S",
            na_rep=""
        )
        buffer.seek(0)

        raw_conn = engine.raw_connection()
        cur = raw_conn.cursor()

        copy_sql = f"""
        COPY {fq_table} ({', '.join(df.columns)})
        FROM STDIN WITH CSV HEADER
        """

        cur.copy_expert(copy_sql, buffer)
        raw_conn.commit()

        logger.info("COPY completed: %d rows loaded into %s", len(df), fq_table)

    except Exception:
        logger.exception("Failed to COPY data into Postgres")
        if raw_conn is not None:
            raw_conn.rollback()
        raise

    finally:
        if raw_conn is not None:
            try:
                cur.close()
            except Exception:
                pass
            raw_conn.close()

    return len(df)


# -----------------------
# Module entry point
# -----------------------
if __name__ == "__main__":
    rows = load_excel_to_raw()
    print(f"Loaded {rows} rows to raw.online_retail")
