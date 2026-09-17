"""
End-to-End Retail Sales Analytics Pipeline Runner
Executes: Data Cleaning -> SQL Setup & Tests -> Notebook Generation -> Dashboard Data
"""

import sys
import os
import subprocess

def run_step(step_name, command):
    print(f"\n{'='*60}")
    print(f"[*] STEP: {step_name}")
    print(f"{'='*60}")
    result = subprocess.run(command, shell=True)
    if result.returncode != 0:
        print(f"[X] Error in {step_name}! Exited with code {result.returncode}")
        sys.exit(result.returncode)
    print(f"[OK] Completed {step_name} successfully.")

def main():
    print("Starting Retail Sales Analytics Pipeline...")
    
    # 1. Clean Data and Create Database
    run_step("Data Cleaning & Database Creation", "python scripts/data_cleaning.py")

    # 2. Test SQL Queries
    run_step("SQL Queries Verification", "python -c \"import sqlite3; conn = sqlite3.connect('data/superstore.db'); c = conn.cursor(); text = open('sql/queries.sql').read(); [c.execute('\\n'.join([l for l in s.split('\\n') if not l.strip().startswith('--')]).strip()) for s in text.split(';') if '\\n'.join([l for l in s.split('\\n') if not l.strip().startswith('--')]).strip()]; print('All SQL queries executed flawlessly.')\"")

    # 3. Build Executed Jupyter Notebook
    run_step("Jupyter Notebook Generation & Chart Export", "python scripts/build_executed_notebook.py")

    # 4. Export Dashboard Data
    run_step("Dashboard Data Export", "python scripts/export_dashboard_data.py")

    print("\n" + "#"*60)
    print("[SUCCESS] PIPELINE COMPLETED SUCCESSFULLY!")
    print("  - Data:       data/superstore_cleaned.csv & data/superstore.db")
    print("  - SQL:        sql/schema.sql & sql/queries.sql")
    print("  - Notebook:   notebook/eda_analysis.ipynb & notebook/charts/")
    print("  - Dashboard:  dashboard/index.html & dashboard/dashboard_screenshot.png")
    print("#"*60 + "\n")

if __name__ == "__main__":
    main()
