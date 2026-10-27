"""
MESS MANAGEMENT SYSTEM - MySQL SETUP & VERIFICATION RUNNER
Builds the `mess_management` database from schema.sql + seed_data.sql
and runs verification queries.

Requires:  pip install mysql-connector-python
Usage:     set MYSQL_PASSWORD=yourpassword   (PowerShell: $env:MYSQL_PASSWORD="...")
           python setup_database.py            # asks before wiping an existing database
           python setup_database.py --force    # no prompt (CI / scripted use)
"""
import os
import sys
import mysql.connector
from db_config import MYSQL_CONFIG, DB_NAME, BASE_DIR, split_sql


def run_script(cursor, filename):
    with open(os.path.join(BASE_DIR, filename), "r", encoding="utf-8") as f:
        for stmt in split_sql(f.read()):
            cursor.execute(stmt)


def confirm_wipe(cursor, force):
    """schema.sql begins with DROP DATABASE, so never run it blindly over existing data."""
    cursor.execute("SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = %s", (DB_NAME,))
    if not cursor.fetchone()[0]:
        return
    cursor.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = %s", (DB_NAME,))
    n_tables = cursor.fetchone()[0]
    print(f"[!] Database `{DB_NAME}` already exists ({n_tables} tables). schema.sql will DROP it.")
    if force:
        return
    if not sys.stdin.isatty() or input("    Type the database name to confirm: ").strip() != DB_NAME:
        print("[ABORT] Nothing changed. Re-run with --force to skip this prompt.")
        sys.exit(2)


def init_database(force=False):
    print(f"[*] Connecting to MySQL at {MYSQL_CONFIG['host']}:{MYSQL_CONFIG['port']} as {MYSQL_CONFIG['user']}")
    conn = mysql.connector.connect(**MYSQL_CONFIG)
    cursor = conn.cursor()
    confirm_wipe(cursor, force)
    print("[*] Executing schema.sql (recreates database)...")
    run_script(cursor, "schema.sql")
    print("[*] Executing seed_data.sql...")
    run_script(cursor, "seed_data.sql")
    conn.commit()
    cursor.close()
    conn.database = DB_NAME
    return conn


def print_table(title, headers, rows):
    print(f"\n{'=' * 75}\n {title.upper()}\n{'=' * 75}")
    rows = [tuple("NULL" if v is None else str(v) for v in r) for r in rows]
    widths = [len(h) for h in headers]
    for r in rows:
        for i, v in enumerate(r):
            widths[i] = max(widths[i], len(v))
    print(" | ".join(h.ljust(widths[i]) for i, h in enumerate(headers)))
    print("-+-".join("-" * w for w in widths))
    for r in rows:
        print(" | ".join(v.ljust(widths[i]) for i, v in enumerate(r)))
    print(f"Total Rows: {len(rows)}")


def run_verifications(conn):
    cur = conn.cursor()

    cur.execute("SHOW TABLES")
    tables = [r[0] for r in cur.fetchall()]
    print(f"\n[*] Created Tables ({len(tables)}): {', '.join(tables)}")

    cur.execute("""
        SELECT s.registration_no, s.full_name, h.block_code, s.room_no,
               s.dietary_preference, s.phone_number
        FROM students s JOIN hostels h ON s.hostel_id = h.hostel_id
        ORDER BY s.student_id LIMIT 6""")
    print_table("Sample Students (Name, Reg No, Room, Veg/Non-Veg)",
                ["Reg No", "Full Name", "Hostel", "Room", "Dietary Pref", "Phone"], cur.fetchall())

    cur.execute("""
        SELECT m.mess_name, s.dietary_preference, COUNT(s.student_id)
        FROM student_mess_subscriptions sub
        JOIN messes m ON sub.mess_id = m.mess_id
        JOIN students s ON sub.student_id = s.student_id
        WHERE sub.status = 'ACTIVE'
          AND CURDATE() BETWEEN sub.start_date AND sub.end_date
          AND s.student_id NOT IN (
              SELECT student_id FROM mess_rebates
              WHERE status = 'APPROVED' AND CURDATE() BETWEEN start_date AND end_date)
        GROUP BY m.mess_name, s.dietary_preference
        ORDER BY m.mess_name, s.dietary_preference""")
    print_table("Daily Kitchen Meal Demand Forecast (Excluding Active Leaves)",
                ["Mess Name", "Diet Category", "Expected Count"], cur.fetchall())

    cur.execute("""
        SELECT s.registration_no, s.full_name, r.start_date, r.end_date, r.reason, r.status
        FROM mess_rebates r JOIN students s ON r.student_id = s.student_id
        WHERE r.status = 'APPROVED' AND CURDATE() BETWEEN r.start_date AND r.end_date""")
    print_table("Approved Mess Rebates / Leaves Active Today",
                ["Reg No", "Student Name", "Start Date", "End Date", "Reason", "Status"], cur.fetchall())

    cur.execute("""
        SELECT s.registration_no, s.full_name, m.mess_name, b.base_fee, b.rebate_amount,
               b.guest_charges, b.net_payable, b.payment_status
        FROM monthly_bills b
        JOIN students s ON b.student_id = s.student_id
        JOIN messes m ON b.mess_id = m.mess_id
        WHERE b.billing_month = 9 AND b.billing_year = 2026""")
    print_table("Monthly Mess Billing Summary (Sept 2026)",
                ["Reg No", "Student Name", "Mess", "Base Fee", "Rebate Disc", "Guest Chg", "Net Payable", "Status"],
                cur.fetchall())

    cur.execute("""
        SELECT m.mess_name, i.item_name, i.category, i.current_stock, i.reorder_threshold, i.unit
        FROM inventory_items i JOIN messes m ON i.mess_id = m.mess_id
        WHERE i.current_stock <= i.reorder_threshold""")
    print_table("Critical Kitchen Low-Stock Alerts",
                ["Mess", "Item Name", "Category", "Stock", "Threshold", "Unit"], cur.fetchall())

    cur.execute("""
        SELECT mess_name, production_date, slot_name, diet_category,
               prepared_kg, waste_kg, waste_pct, waste_cost_inr
        FROM v_waste_summary
        ORDER BY production_date DESC, mess_name, slot_name""")
    print_table("Food Waste Summary (kg / % / INR)",
                ["Mess", "Date", "Slot", "Diet", "Cooked kg", "Waste kg", "Waste %", "Cost INR"],
                cur.fetchall())

    cur.close()
    print("\n[OK] Verification queries completed.\n")


if __name__ == "__main__":
    try:
        connection = init_database(force="--force" in sys.argv)
        run_verifications(connection)
        connection.close()
    except mysql.connector.Error as e:
        print(f"[ERROR] MySQL error: {e}")
        sys.exit(1)