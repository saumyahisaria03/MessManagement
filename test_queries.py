"""
Runs every query in queries.sql against the MySQL `mess_management` database and
checks each one returns at least the expected number of rows on the seed data.
Run setup_database.py first.
"""
import os
import sys
import mysql.connector
from db_config import MYSQL_CONFIG, DB_NAME, BASE_DIR, split_titled_queries

# Minimum rows each query must return on the seeded data (exact counts are noted
# where the seed pins them). A query that "runs" but returns nothing is a failure.
MIN_ROWS = {1: 1, 2: 1, 3: 2, 4: 10, 5: 3, 6: 3, 7: 5, 8: 4, 9: 3, 10: 3, 11: 2, 12: 1}


def test_all_queries():
    conn = mysql.connector.connect(database=DB_NAME, **MYSQL_CONFIG)
    cur = conn.cursor()
    with open(os.path.join(BASE_DIR, "queries.sql"), "r", encoding="utf-8") as f:
        pre, queries = split_titled_queries(f.read())
    for stmt in pre:               # USE / SET @on_date ... (session variables)
        cur.execute(stmt)
    print(f"[*] Testing {len(queries)} queries from queries.sql...")
    failures = []
    for num, title, stmts in queries:
        rows = []
        for stmt in stmts:
            cur.execute(stmt)
            if cur.with_rows:
                rows = cur.fetchall()
        need = MIN_ROWS.get(num, 1)
        ok = len(rows) >= need
        print(f"  [{'+' if ok else '!'}] Q{num} {title}: {len(rows)} rows (need >= {need})")
        if not ok:
            failures.append(num)
    cur.close()
    conn.close()
    if failures:
        print(f"[FAIL] Queries with too few rows: {failures}")
        sys.exit(1)
    print(f"[OK] All {len(queries)} queries ran and returned the expected rows!")


if __name__ == "__main__":
    test_all_queries()