# tests/test_smoke.py
from src.db import get_engine
from sqlalchemy import text

def test_fact_exists():
    engine = get_engine()
    with engine.connect() as conn:
        row = conn.execute(text("SELECT 1 FROM fact_sales LIMIT 1")).fetchone()
    assert row is not None
