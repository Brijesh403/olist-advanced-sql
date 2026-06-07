"""
load_reviews.py
---------------
Loads olist_order_reviews_dataset.csv into the MySQL `order_reviews` table.

Why not LOAD DATA INFILE?
The review_comment_message field contains embedded newlines and imperfectly
escaped quotes. MySQL's line parser fails at row 77,917. pandas handles
multi-line quoted fields natively, so we use it as the loader here.

Usage:
    Set DB credentials as environment variables before running:
        export DB_USER=root
        export DB_PASS=your_password_here

    Then:
        python python/load_reviews.py
"""

import os
import pandas as pd
from sqlalchemy import create_engine
from pathlib import Path

# --- DB connection — credentials from environment variables ---
DB_USER = os.environ.get("DB_USER", "root")
DB_PASS = os.environ.get("DB_PASS", "")
DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
DB_PORT = os.environ.get("DB_PORT", "3306")
DB_NAME = os.environ.get("DB_NAME", "olist")

engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# --- locate CSV relative to this script ---
BASE_DIR = Path(__file__).resolve().parent.parent
CSV = BASE_DIR / "data" / "olist_order_reviews_dataset.csv"

# --- load ---
df = pd.read_csv(CSV)

# empty strings / NaN -> None so MySQL stores NULL
df = df.where(pd.notnull(df), None)

# append into the existing (empty) table; if_exists="append" does not recreate it
df.to_sql("order_reviews", engine, if_exists="append", index=False, chunksize=5000)

print(f"Loaded {len(df):,} review rows into `order_reviews`")