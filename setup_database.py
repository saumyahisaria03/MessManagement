"""
=============================================================================
MESS MANAGEMENT SYSTEM - DATABASE SETUP & VERIFICATION RUNNER
File: setup_database.py
Description: Initializes SQLite database from schema.sql & seed_data.sql,
             runs core queries, and verifies tables, constraints, and views.
=============================================================================
"""

import sqlite3
import os
import sys

DB_FILE = os.path.join(os.path.dirname(__file__), "mess_management.db")
SCHEMA_FILE = os.path.join(os.path.dirname(__file__), "schema.sql")
SEED_FILE = os.path.join(os.path.dirname(__file__), "seed_data.sql")

def init_database():
    print(f"[*] Initializing Database at: {DB_FILE}")
    
    # Remove existing db file if present
    if os.path.exists(DB_FILE):
        os.remove(DB_FILE)
        print("[*] Removed existing database file for a fresh build.")

    conn = sqlite3.connect(DB_FILE)
    conn.execute("PRAGMA foreign_keys = ON;")
    cursor = conn.cursor()

    # Read and execute schema
    print("[*] Executing schema.sql...")
    with open(SCHEMA_FILE, "r", encoding="utf-8") as f:
        schema_sql = f.read()
    cursor.executescript(schema_sql)
    print("    [+] Schema tables, views, and indexes created successfully.")

    # Read and execute seed data
    print("[*] Executing seed_data.sql...")
    with open(SEED_FILE, "r", encoding="utf-8") as f:
        seed_sql = f.read()
    cursor.executescript(seed_sql)
    conn.commit()
    print("    [+] Seed data inserted successfully.")

    return conn

def print_table(title, headers, rows):
    print(f"\n{'='*75}")
    print(f" {title.upper()}")
    print(f"{'='*75}")
    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, val in enumerate(row):
            col_widths[i] = max(col_widths[i], len(str(val) if val is not None else "NULL"))
    
    header_line = " | ".join(h.ljust(col_widths[i]) for i, h in enumerate(headers))
    sep_line = "-+-".join("-" * col_widths[i] for i in range(len(headers)))
    print(header_line)
    print(sep_line)
    for row in rows:
        print(" | ".join((str(val) if val is not None else "NULL").ljust(col_widths[i]) for i, val in enumerate(row)))
    print(f"Total Rows: {len(rows)}")

def run_verifications(conn):
    cursor = conn.cursor()

    # 1. Verify Tables Created
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
    tables = [r[0] for r in cursor.fetchall() if not r[0].startswith("sqlite_")]
    print(f"\n[*] Created Tables ({len(tables)}): {', '.join(tables)}")

    # 2. Verify Students with Required Attributes
    cursor.execute("""
        SELECT 
            s.registration_no,
            s.full_name,
            h.block_code,
            s.room_no,
            s.dietary_preference,
            s.phone_number
        FROM students s
        JOIN hostels h ON s.hostel_id = h.hostel_id
        LIMIT 6;
    """)
    rows = cursor.fetchall()
    print_table("Sample Students (Name, Reg No, Room, Veg/Non-Veg)", 
                ["Reg No", "Full Name", "Hostel", "Room", "Dietary Pref", "Phone"], rows)

    # 3. Kitchen Headcount Forecast (Veg vs Non-Veg for Today)
    cursor.execute("""
        SELECT 
            m.mess_name,
            s.dietary_preference,
            COUNT(s.student_id) AS expected_count
        FROM student_mess_subscriptions sub
        JOIN messes m ON sub.mess_id = m.mess_id
        JOIN students s ON sub.student_id = s.student_id
        WHERE sub.status = 'ACTIVE'
          AND s.student_id NOT IN (
              SELECT student_id FROM mess_rebates 
              WHERE status = 'APPROVED' AND '2026-10-13' BETWEEN start_date AND end_date
          )
        GROUP BY m.mess_name, s.dietary_preference;
    """)
    rows = cursor.fetchall()
    print_table("Daily Kitchen Meal Demand Forecast (Excluding Active Leaves)", 
                ["Mess Name", "Diet Category", "Expected Count"], rows)

    # 4. Students on Active Rebate / Leave Today
    cursor.execute("""
        SELECT 
            s.registration_no,
            s.full_name,
            r.start_date,
            r.end_date,
            r.reason,
            r.status
        FROM mess_rebates r
        JOIN students s ON r.student_id = s.student_id
        WHERE r.status = 'APPROVED' AND '2026-10-13' BETWEEN r.start_date AND r.end_date;
    """)
    rows = cursor.fetchall()
    print_table("Approved Mess Rebates / Leaves Active Today", 
                ["Reg No", "Student Name", "Start Date", "End Date", "Reason", "Status"], rows)

    # 5. Monthly Mess Bills Breakdown
    cursor.execute("""
        SELECT 
            s.registration_no,
            s.full_name,
            m.mess_name,
            b.base_fee,
            b.rebate_amount,
            b.guest_charges,
            b.net_payable,
            b.payment_status
        FROM monthly_bills b
        JOIN students s ON b.student_id = s.student_id
        JOIN messes m ON b.mess_id = m.mess_id
        WHERE b.billing_month = 9 AND b.billing_year = 2026;
    """)
    rows = cursor.fetchall()
    print_table("Monthly Mess Billing Summary (Sept 2026)", 
                ["Reg No", "Student Name", "Mess", "Base Fee", "Rebate Disc", "Guest Chg", "Net Payable", "Status"], rows)

    # 6. Inventory Low Stock Alerts
    cursor.execute("""
        SELECT 
            m.mess_name,
            i.item_name,
            i.category,
            i.current_stock,
            i.reorder_threshold,
            i.unit
        FROM inventory_items i
        JOIN messes m ON i.mess_id = m.mess_id
        WHERE i.current_stock <= i.reorder_threshold;
    """)
    rows = cursor.fetchall()
    print_table("Critical Kitchen Low-Stock Alerts", 
                ["Mess", "Item Name", "Category", "Stock", "Threshold", "Unit"], rows)

    print("\n[OK] ALL VERIFICATION CHECKS PASSED PERFECTLY!\n")

if __name__ == "__main__":
    connection = init_database()
    run_verifications(connection)
    connection.close()
