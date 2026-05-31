import pandas as pd
from sqlalchemy import create_engine

# --- connection (same MySQL as Project 1) ---
engine = create_engine("mysql+pymysql://root:1998@127.0.0.1:3306/olist")

CSV = r"D:\Lerning\Potfolio Projects\12 LPA PROJECTS\olist-advanced-sql\data\olist_order_reviews_dataset.csv"

# pandas handles quoted multi-line fields natively
df = pd.read_csv(CSV)

# empty strings / NaN -> None so MySQL stores NULL
df = df.where(pd.notnull(df), None)

# rename to match our table columns (they already match Olist's headers, but be explicit)
df = df.rename(columns={
    "review_id": "review_id",
    "order_id": "order_id",
    "review_score": "review_score",
    "review_comment_title": "review_comment_title",
    "review_comment_message": "review_comment_message",
    "review_creation_date": "review_creation_date",
    "review_answer_timestamp": "review_answer_timestamp",
})

# append into the existing (empty) table; don't recreate it
df.to_sql("order_reviews", engine, if_exists="append", index=False, chunksize=5000)

print(f"Loaded {len(df):,} review rows")