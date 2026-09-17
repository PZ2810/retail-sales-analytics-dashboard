"""
Data Cleaning & Feature Engineering Pipeline
Superstore Sales Analytics
"""

import pandas as pd
import numpy as np
import sqlite3
import os

def clean_data():
    raw_path = os.path.join("data", "superstore_raw.csv")
    cleaned_path = os.path.join("data", "superstore_cleaned.csv")
    db_path = os.path.join("data", "superstore.db")

    print(f"Loading raw data from {raw_path}...")
    # Load with windows-1252 / latin1 encoding as standard for Superstore dataset
    df = pd.read_csv(raw_path, encoding='windows-1252')
    
    initial_rows = len(df)
    print(f"Initial row count: {initial_rows}")
    print(f"Columns: {list(df.columns)}")

    # 1. Check for duplicates
    dup_count = df.duplicated().sum()
    print(f"Duplicate rows found: {dup_count}")
    if dup_count > 0:
        df = df.drop_duplicates()

    # 2. Date parsing (dates in dataset are M/D/YYYY or MM/DD/YYYY)
    df['Order Date'] = pd.to_datetime(df['Order Date'], format='%m/%d/%Y', errors='coerce')
    # If any failed, try dayfirst=False general parser
    if df['Order Date'].isna().sum() > 0:
        df['Order Date'] = pd.to_datetime(df['Order Date'])
        
    df['Ship Date'] = pd.to_datetime(df['Ship Date'], format='%m/%d/%Y', errors='coerce')
    if df['Ship Date'].isna().sum() > 0:
        df['Ship Date'] = pd.to_datetime(df['Ship Date'])

    # 3. Handle Postal Code (convert to string, pad with zeros if 5-digit US zip, handle NaN)
    df['Postal Code'] = df['Postal Code'].fillna(5408).astype(int).astype(str).str.zfill(5)

    # 4. Standardize text columns
    text_cols = ['Ship Mode', 'Segment', 'Country', 'City', 'State', 'Region', 'Category', 'Sub-Category']
    for col in text_cols:
        df[col] = df[col].astype(str).str.strip()

    # 5. Feature Engineering
    # Shipping duration
    df['Ship Duration Days'] = (df['Ship Date'] - df['Order Date']).dt.days

    # Time dimensions
    df['Order Year'] = df['Order Date'].dt.year
    df['Order Month'] = df['Order Date'].dt.month
    df['Order Month Name'] = df['Order Date'].dt.strftime('%b')
    df['Order YearMonth'] = df['Order Date'].dt.strftime('%Y-%m')
    df['Order Quarter'] = df['Order Date'].dt.to_period('Q').astype(str)

    # Financial & margin metrics
    # Sales and Profit rounding
    df['Sales'] = df['Sales'].round(2)
    df['Profit'] = df['Profit'].round(2)
    df['Discount'] = df['Discount'].round(2)
    
    # Profit Margin % (handle division by zero if sales == 0, though sales > 0 in this dataset)
    df['Profit Margin %'] = np.where(df['Sales'] > 0, (df['Profit'] / df['Sales']) * 100, 0).round(2)
    df['Is Profitable'] = (df['Profit'] > 0).astype(int)

    # Discount Tiers
    def categorize_discount(d):
        if d == 0:
            return '0% (No Discount)'
        elif d <= 0.10:
            return '1-10% (Low)'
        elif d <= 0.20:
            return '11-20% (Moderate)'
        else:
            return '>20% (High / Deep)'

    df['Discount Tier'] = df['Discount'].apply(categorize_discount)

    # Sort deterministically
    df = df.sort_values(by=['Order Date', 'Row ID']).reset_index(drop=True)

    # Save cleaned CSV
    print(f"Saving cleaned dataset to {cleaned_path}...")
    df.to_csv(cleaned_path, index=False)
    print(f"Cleaned dataset saved: {len(df)} rows, {len(df.columns)} columns.")

    # 6. Load into SQLite Database for SQL verification
    print(f"Loading into SQLite database at {db_path}...")
    conn = sqlite3.connect(db_path)
    
    # Prepare SQL-friendly column names
    sql_df = df.copy()
    sql_df.columns = [c.replace(' ', '_').replace('-', '_').replace('%', 'Pct') for c in sql_df.columns]
    
    # Format dates as ISO string YYYY-MM-DD
    sql_df['Order_Date'] = sql_df['Order_Date'].dt.strftime('%Y-%m-%d')
    sql_df['Ship_Date'] = sql_df['Ship_Date'].dt.strftime('%Y-%m-%d')

    sql_df.to_sql('superstore', conn, if_exists='replace', index=False)
    
    # Create indexes for analytical query speed
    cursor = conn.cursor()
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_order_date ON superstore(Order_Date);")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_region ON superstore(Region);")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_category ON superstore(Category);")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_sub_category ON superstore(Sub_Category);")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_customer_id ON superstore(Customer_ID);")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_discount_tier ON superstore(Discount_Tier);")
    conn.commit()
    conn.close()
    print("SQLite database created and indexed successfully.")

    # Print baseline summary
    total_sales = df['Sales'].sum()
    total_profit = df['Profit'].sum()
    margin = (total_profit / total_sales) * 100
    total_orders = df['Order ID'].nunique()
    total_customers = df['Customer ID'].nunique()
    print("=" * 50)
    print("BASELINE METRICS SUMMARY:")
    print(f"  Total Revenue:      ${total_sales:,.2f}")
    print(f"  Total Profit:       ${total_profit:,.2f}")
    print(f"  Overall Margin:     {margin:.2f}%")
    print(f"  Total Orders:       {total_orders:,}")
    print(f"  Total Customers:    {total_customers:,}")
    print(f"  Profitable Orders:  {(df['Profit'] > 0).mean()*100:.1f}%")
    print("=" * 50)

if __name__ == "__main__":
    clean_data()
