"""
Runs every query in queries.sql against the MySQL `mess_management` database.
Run setup_database.py first.
"""
import os
import mysql.connector
from db_config import MYSQL_CONFIG, DB_NAME, BASE_DIR


def split_queries(text):
    """Split on ';' and keep only chunks that contain a SELECT (preserves title comments)."""
    out = []
    for chunk in text.split(";"):
        body = "\n".join(l for l in chunk.splitlines() if not l.strip().startswith("--")).strip()
        if body.upper().startswith("SELECT"):
            title = next((l.strip(" -") for l in chunk.splitlines() if "QUERY" in l), f"Query {len(out) + 1}")
            out.append((title, body))
    return out


def test_all_queries():
    conn = mysql.connector.connect(database=DB_NAME, **MYSQL_CONFIG)
    cur = conn.cursor()
    with open(os.path.join(BASE_DIR, "queries.sql"), "r", encoding="utf-8") as f:
        queries = split_queries(f.read())
    print(f"[*] Testing {len(queries)} queries from queries.sql...")
    for title, sql in queries:
        cur.execute(sql)
        print(f"  [+] {title}: returned {len(cur.fetchall())} rows (Success)")
    cur.close()
    conn.close()
    print(f"[OK] All {len(queries)} queries ran successfully!")


if __name__ == "__main__":
    test_all_queries()