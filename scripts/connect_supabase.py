"""
Upload Cleaned Superstore Data to Supabase (PostgreSQL)
"""

import os
import json
import pandas as pd
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables from .env file
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

def upload_to_supabase():
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("[!] Missing credentials.")
        print("Please set SUPABASE_URL and SUPABASE_KEY in your .env file or environment variables.")
        return

    print(f"Connecting to Supabase at {SUPABASE_URL}...")
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

    csv_path = os.path.join("data", "superstore_cleaned.csv")
    print(f"Loading data from {csv_path}...")
    df = pd.read_csv(csv_path)

    # Convert column names to lower_snake_case for PostgreSQL standards
    df.columns = [
        c.lower()
        .replace(' ', '_')
        .replace('-', '_')
        .replace('%', 'pct')
        for c in df.columns
    ]

    # Convert NaN to None for proper JSON serialization
    df = df.where(pd.notnull(df), None)
    records = df.to_dict(orient="records")
    total_records = len(records)
    print(f"Total records to insert: {total_records:,}")

    # Insert in batches of 500 rows
    batch_size = 500
    inserted = 0
    has_error = False

    for i in range(0, total_records, batch_size):
        batch = records[i:i + batch_size]
        try:
            supabase.table("superstore").upsert(batch).execute()
            inserted += len(batch)
            print(f"  Inserted rows {i + 1} to {min(i + batch_size, total_records)}...")
        except Exception as e:
            print(f"\n[Error] Upload stopped: {e}")
            print("\n>> Reason: The 'superstore' table does not exist yet in your Supabase project.")
            print(">> Solution: Run the SQL in 'sql/supabase_setup.sql' inside Supabase SQL Editor first.")
            has_error = True
            break

    if not has_error and inserted == total_records:
        print(f"\n[SUCCESS] All {total_records:,} rows uploaded to Supabase 'superstore' table!")
    else:
        print(f"\n[INCOMPLETE] Uploaded {inserted} of {total_records} rows.")

if __name__ == "__main__":
    upload_to_supabase()
