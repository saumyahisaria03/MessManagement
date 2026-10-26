-- ============================================================================
-- MESS MANAGEMENT SYSTEM BACKEND DATABASE SCHEMA
-- File: schema.sql
-- Description: Complete Relational DDL Schema with Constraints, Foreign Keys, 
--              Indexes, and Analytical Views.
-- Compatible with: SQLite, PostgreSQL, MySQL (ANSI SQL standard)
-- ============================================================================

-- Disable foreign key checks during schema creation if needed
PRAGMA foreign_keys = ON;

-- Drop views if exist
DROP VIEW IF EXISTS v_mess_ratings_summary;
DROP VIEW IF EXISTS v_daily_meal_demand;
DROP VIEW IF EXISTS v_student_billing_summary;
DROP VIEW IF EXISTS v_active_student_directory;

-- Drop tables in reverse topological order of dependencies
DROP TABLE IF EXISTS inventory_items;
DROP TABLE IF EXISTS mess_feedbacks;
DROP TABLE IF EXISTS guest_meals;
DROP TABLE IF EXISTS monthly_bills;
DROP TABLE IF EXISTS mess_rebates;
DROP TABLE IF EXISTS meal_attendance;
DROP TABLE IF EXISTS weekly_menus;
DROP TABLE IF EXISTS student_mess_subscriptions;
DROP TABLE IF EXISTS meal_slots;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS messes;
DROP TABLE IF EXISTS hostels;

-- ============================================================================
-- 1. HOSTELS TABLE
-- Stores hostel buildings/blocks where students reside
-- ============================================================================
CREATE TABLE hostels (
    hostel_id INTEGER PRIMARY KEY AUTOINCREMENT,
    hostel_name VARCHAR(50) NOT NULL UNIQUE,
    block_code VARCHAR(10) NOT NULL UNIQUE,
    gender_type VARCHAR(10) NOT NULL CHECK (gender_type IN ('MALE', 'FEMALE', 'COED')),
    warden_name VARCHAR(100) NOT NULL,
    warden_contact VARCHAR(15) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 2. MESSES TABLE
-- Stores dining halls / messes operating in the institution
-- ============================================================================
CREATE TABLE messes (
    mess_id INTEGER PRIMARY KEY AUTOINCREMENT,
    mess_name VARCHAR(100) NOT NULL UNIQUE,
    mess_type VARCHAR(20) NOT NULL CHECK (mess_type IN ('PURE_VEG', 'VEG_NON_VEG', 'SPECIAL_DIET')),
    hostel_id INTEGER,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    caterer_name VARCHAR(100) NOT NULL,
    caterer_contact VARCHAR(15) NOT NULL,
    monthly_base_fee DECIMAL(10, 2) NOT NULL CHECK (monthly_base_fee >= 0),
    per_day_rebate_rate DECIMAL(10, 2) NOT NULL CHECK (per_day_rebate_rate >= 0),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'UNDER_MAINTENANCE', 'CLOSED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hostel_id) REFERENCES hostels(hostel_id) ON DELETE SET NULL
);

-- ============================================================================
-- 3. STUDENTS TABLE
-- Stores student profile, including:
-- - Name (full_name)
-- - Registration number (registration_no - UNIQUE)
-- - Room (room_no & hostel_id)
-- - Veg / Non-Veg Food choice (dietary_preference)
-- - Additional contact, department, and academic attributes
-- ============================================================================
CREATE TABLE students (
    student_id INTEGER PRIMARY KEY AUTOINCREMENT,
    registration_no VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    hostel_id INTEGER NOT NULL,
    room_no VARCHAR(10) NOT NULL,
    dietary_preference VARCHAR(15) NOT NULL CHECK (dietary_preference IN ('VEG', 'NON_VEG', 'JAIN', 'EGG_ONLY')),
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(15) NOT NULL,
    department VARCHAR(50) NOT NULL,
    year_of_study INTEGER NOT NULL CHECK (year_of_study BETWEEN 1 AND 5),
    emergency_contact VARCHAR(15),
    blood_group VARCHAR(5),
    account_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (account_status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'ALUMNI')),
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hostel_id) REFERENCES hostels(hostel_id) ON DELETE RESTRICT
);

-- ============================================================================
-- 4. MEAL SLOTS TABLE
-- Defines meal timings and default individual rates for guest billing/calculations
-- ============================================================================
CREATE TABLE meal_slots (
    slot_id INTEGER PRIMARY KEY AUTOINCREMENT,
    slot_name VARCHAR(20) NOT NULL UNIQUE CHECK (slot_name IN ('BREAKFAST', 'LUNCH', 'SNACKS', 'DINNER')),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    guest_rate DECIMAL(8, 2) NOT NULL CHECK (guest_rate > 0)
);

-- ============================================================================
-- 5. STUDENT MESS SUBSCRIPTIONS TABLE
-- Links students to a specific mess with a membership validity period
-- ============================================================================
CREATE TABLE student_mess_subscriptions (
    subscription_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    mess_id INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    plan_type VARCHAR(20) NOT NULL CHECK (plan_type IN ('MONTHLY', 'SEMESTER', 'ANNUAL')),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED', 'TRANSFERRED', 'CANCELLED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    CHECK (end_date >= start_date)
);

-- ============================================================================
-- 6. WEEKLY MENUS TABLE
-- Weekly revolving schedule of dishes served by each mess
-- ============================================================================
CREATE TABLE weekly_menus (
    menu_id INTEGER PRIMARY KEY AUTOINCREMENT,
    mess_id INTEGER NOT NULL,
    day_of_week VARCHAR(10) NOT NULL CHECK (day_of_week IN ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')),
    slot_id INTEGER NOT NULL,
    diet_category VARCHAR(15) NOT NULL CHECK (diet_category IN ('VEG', 'NON_VEG', 'COMMON')),
    menu_items TEXT NOT NULL,
    special_notes VARCHAR(255),
    FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES meal_slots(slot_id) ON DELETE CASCADE,
    UNIQUE (mess_id, day_of_week, slot_id, diet_category)
);

-- ============================================================================
-- 7. MEAL ATTENDANCE TABLE
-- Real-time check-in log when a student takes a meal (via RFID/Biometric/Token)
-- Prevents double swipes in the same slot on the same day
-- ============================================================================
CREATE TABLE meal_attendance (
    attendance_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    mess_id INTEGER NOT NULL,
    slot_id INTEGER NOT NULL,
    attendance_date DATE NOT NULL,
    diet_served VARCHAR(15) NOT NULL CHECK (diet_served IN ('VEG', 'NON_VEG', 'JAIN', 'EGG_ONLY')),
    verification_type VARCHAR(20) DEFAULT 'RFID' CHECK (verification_type IN ('RFID', 'BIOMETRIC', 'QR_SCAN', 'MANUAL')),
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    FOREIGN KEY (slot_id) REFERENCES meal_slots(slot_id) ON DELETE RESTRICT,
    UNIQUE (student_id, slot_id, attendance_date)
);

-- ============================================================================
-- 8. MESS REBATES / LEAVE REQUESTS TABLE
-- When students are away, they apply for rebate to deduct mess fees
-- ============================================================================
CREATE TABLE mess_rebates (
    rebate_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(15) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    approved_by VARCHAR(100),
    decision_remarks VARCHAR(255),
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    CHECK (end_date >= start_date)
);

-- ============================================================================
-- 9. MONTHLY BILLS TABLE
-- Monthly mess billing statement generated for each student
-- ============================================================================
CREATE TABLE monthly_bills (
    bill_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    mess_id INTEGER NOT NULL,
    billing_month INTEGER NOT NULL CHECK (billing_month BETWEEN 1 AND 12),
    billing_year INTEGER NOT NULL CHECK (billing_year >= 2020),
    base_fee DECIMAL(10, 2) NOT NULL CHECK (base_fee >= 0),
    rebate_days INTEGER DEFAULT 0 CHECK (rebate_days >= 0),
    rebate_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (rebate_amount >= 0),
    guest_charges DECIMAL(10, 2) DEFAULT 0.00 CHECK (guest_charges >= 0),
    fines_or_extras DECIMAL(10, 2) DEFAULT 0.00 CHECK (fines_or_extras >= 0),
    net_payable DECIMAL(10, 2) NOT NULL CHECK (net_payable >= 0),
    payment_status VARCHAR(15) DEFAULT 'UNPAID' CHECK (payment_status IN ('UNPAID', 'PAID', 'OVERDUE', 'WAIVED')),
    due_date DATE NOT NULL,
    paid_at TIMESTAMP,
    transaction_reference VARCHAR(50),
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE RESTRICT,
    FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    UNIQUE (student_id, billing_month, billing_year)
);

-- ============================================================================
-- 10. GUEST MEALS TABLE
-- Allows students to purchase or book guest meal vouchers
-- ============================================================================
CREATE TABLE guest_meals (
    guest_meal_id INTEGER PRIMARY KEY AUTOINCREMENT,
    host_student_id INTEGER NOT NULL,
    mess_id INTEGER NOT NULL,
    slot_id INTEGER NOT NULL,
    booking_date DATE NOT NULL,
    guest_count INTEGER NOT NULL CHECK (guest_count > 0),
    diet_preference VARCHAR(15) NOT NULL CHECK (diet_preference IN ('VEG', 'NON_VEG')),
    total_charge DECIMAL(10, 2) NOT NULL CHECK (total_charge >= 0),
    status VARCHAR(15) DEFAULT 'BOOKED' CHECK (status IN ('BOOKED', 'CONSUMED', 'CANCELLED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (host_student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    FOREIGN KEY (slot_id) REFERENCES meal_slots(slot_id) ON DELETE RESTRICT
);

-- ============================================================================
-- 11. MESS FEEDBACKS TABLE
-- Student complaints, quality ratings, and food hygiene ratings
-- ============================================================================
CREATE TABLE mess_feedbacks (
    feedback_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    mess_id INTEGER NOT NULL,
    slot_id INTEGER,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    category VARCHAR(30) NOT NULL CHECK (category IN ('FOOD_QUALITY', 'HYGIENE', 'PORTION_SIZE', 'STAFF_BEHAVIOR', 'PUNCTUALITY', 'OTHER')),
    comments TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'UNDER_REVIEW', 'RESOLVED')),
    action_taken TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    FOREIGN KEY (slot_id) REFERENCES meal_slots(slot_id) ON DELETE SET NULL
);

-- ============================================================================
-- 12. INVENTORY ITEMS TABLE
-- Raw materials and ration stock tracking for kitchen operations
-- ============================================================================
CREATE TABLE inventory_items (
    item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    mess_id INTEGER NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    category VARCHAR(30) NOT NULL CHECK (category IN ('GRAINS_PULSES', 'VEGETABLES', 'DAIRY', 'MEAT_POULTRY', 'SPICES_OIL', 'SNACKS_BEVERAGES', 'CLEANING_OTHERS')),
    unit VARCHAR(20) NOT NULL CHECK (unit IN ('KG', 'LITRE', 'PACKET', 'DOZEN', 'UNIT')),
    current_stock DECIMAL(10, 2) NOT NULL CHECK (current_stock >= 0),
    reorder_threshold DECIMAL(10, 2) NOT NULL CHECK (reorder_threshold >= 0),
    last_restocked_date DATE,
    FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE CASCADE,
    UNIQUE (mess_id, item_name)
);

-- ============================================================================
-- PERFORMANCE & LOOKUP INDEXES
-- ============================================================================
CREATE INDEX idx_students_reg_no ON students(registration_no);
CREATE INDEX idx_students_hostel_room ON students(hostel_id, room_no);
CREATE INDEX idx_students_diet ON students(dietary_preference);
CREATE INDEX idx_attendance_date_slot ON meal_attendance(attendance_date, slot_id);
CREATE INDEX idx_attendance_student ON meal_attendance(student_id, attendance_date);
CREATE INDEX idx_rebates_dates ON mess_rebates(start_date, end_date, status);
CREATE INDEX idx_bills_student_month ON monthly_bills(student_id, billing_year, billing_month);
CREATE INDEX idx_bills_payment_status ON monthly_bills(payment_status);
CREATE INDEX idx_feedback_mess_rating ON mess_feedbacks(mess_id, rating);

-- ============================================================================
-- DATABASE VIEWS FOR CORE BUSINESS OPERATIONS
-- ============================================================================

-- View 1: Active Student Directory with current Mess Allocation & Dietary Choice
CREATE VIEW v_active_student_directory AS
SELECT 
    s.student_id,
    s.registration_no,
    s.full_name,
    h.hostel_name,
    h.block_code,
    s.room_no,
    s.dietary_preference,
    s.email,
    s.phone_number,
    s.department,
    s.year_of_study,
    m.mess_id,
    m.mess_name,
    sub.plan_type,
    sub.start_date AS subscription_start,
    sub.end_date AS subscription_end
FROM students s
JOIN hostels h ON s.hostel_id = h.hostel_id
LEFT JOIN student_mess_subscriptions sub ON s.student_id = sub.student_id AND sub.status = 'ACTIVE'
LEFT JOIN messes m ON sub.mess_id = m.mess_id
WHERE s.account_status = 'ACTIVE';

-- View 2: Monthly Billing Summary per Student with Net Balances
CREATE VIEW v_student_billing_summary AS
SELECT 
    b.bill_id,
    s.registration_no,
    s.full_name,
    h.block_code || '-' || s.room_no AS room_identifier,
    m.mess_name,
    b.billing_month,
    b.billing_year,
    b.base_fee,
    b.rebate_days,
    b.rebate_amount,
    b.guest_charges,
    b.fines_or_extras,
    b.net_payable,
    b.payment_status,
    b.due_date,
    b.paid_at,
    b.transaction_reference
FROM monthly_bills b
JOIN students s ON b.student_id = s.student_id
JOIN hostels h ON s.hostel_id = h.hostel_id
JOIN messes m ON b.mess_id = m.mess_id;

-- View 3: Mess Satisfaction Ratings and Feedback Aggregation
CREATE VIEW v_mess_ratings_summary AS
SELECT 
    m.mess_id,
    m.mess_name,
    m.mess_type,
    COUNT(f.feedback_id) AS total_feedbacks,
    ROUND(AVG(f.rating), 2) AS average_rating,
    SUM(CASE WHEN f.rating >= 4 THEN 1 ELSE 0 END) AS positive_reviews_count,
    SUM(CASE WHEN f.rating <= 2 THEN 1 ELSE 0 END) AS complaints_count
FROM messes m
LEFT JOIN mess_feedbacks f ON m.mess_id = f.mess_id
GROUP BY m.mess_id, m.mess_name, m.mess_type;
