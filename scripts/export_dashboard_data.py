"""
Export compact JSON dataset for Interactive Web Dashboard
"""

import pandas as pd
import json
import os

def export_data():
    df = pd.read_csv('data/superstore_cleaned.csv')
    
    # Compact record structure for real-time in-browser aggregation
    compact = []
    for _, r in df.iterrows():
        compact.append({
            'id': r['Order ID'],
            'y': int(r['Order Year']),
            'm': int(r['Order Month']),
            'ym': r['Order YearMonth'],
            'reg': r['Region'],
            'seg': r['Segment'],
            'cat': r['Category'],
            'sub': r['Sub-Category'],
            'prod': r['Product Name'],
            's': float(r['Sales']),
            'p': float(r['Profit']),
            'd': float(r['Discount']),
            'tier': r['Discount Tier']
        })
        
    os.makedirs('dashboard', exist_ok=True)
    json_path = os.path.join('dashboard', 'data.json')
    js_path = os.path.join('dashboard', 'data.js')
    
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(compact, f)
        
    with open(js_path, 'w', encoding='utf-8') as f:
        f.write("window.SUPERSTORE_DATA = ")
        json.dump(compact, f)
        f.write(";\n")
        
    print(f"Exported {len(compact)} records to {json_path} and {js_path}.")

if __name__ == "__main__":
    export_data()
