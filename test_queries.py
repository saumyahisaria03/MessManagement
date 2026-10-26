"""
Test runner to verify all 12 queries in queries.sql against mess_management.db
"""

import sqlite3
import os

DB_FILE = os.path.join(os.path.dirname(__file__), "mess_management.db")
QUERIES_FILE = os.path.join(os.path.dirname(__file__), "queries.sql")

def test_all_queries():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    with open(QUERIES_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    # Split queries by semicolon, ignoring comments
    statements = [stmt.strip() for stmt in content.split(";") if stmt.strip()]
    
    print(f"[*] Testing {len(statements)} queries from queries.sql...")
    for idx, stmt in enumerate(statements, 1):
        try:
            cursor.execute(stmt)
            rows = cursor.fetchall()
            # Extract query title from first comment line if present
            title = f"Query {idx}"
            for line in stmt.splitlines():
                if "QUERY" in line:
                    title = line.strip(" -/*")
                    break
            print(f"  [+] {title}: returned {len(rows)} rows (Success)")
        except Exception as e:
            print(f"  [-] Query {idx} failed: {e}")
            raise

    conn.close()
    print("[OK] All 12 queries in queries.sql ran successfully!")

if __name__ == "__main__":
    test_all_queries()
