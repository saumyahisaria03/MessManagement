-- ============================================================================
-- MESS MANAGEMENT SYSTEM - DATABASE SCHEMA (MySQL 8.0.16+ / MySQL Workbench)
-- File: schema.sql
-- Run this file FIRST, then seed_data.sql, then queries.sql.
-- WARNING: DROPS and recreates the whole `mess_management` database.
-- ============================================================================

DROP DATABASE IF EXISTS mess_management;
CREATE DATABASE mess_management CHARACTER SET utf8mb4;   -- server-default utf8mb4 collation (works on MySQL 5.7+/8.x)
USE mess_management;

-- 1. HOSTELS
CREATE TABLE hostels (
    hostel_id INT PRIMARY KEY AUTO_INCREMENT,
    hostel_name VARCHAR(50) NOT NULL UNIQUE,
    block_code VARCHAR(10) NOT NULL UNIQUE,
    gender_type VARCHAR(10) NOT NULL,
    warden_name VARCHAR(100) NOT NULL,
    warden_contact VARCHAR(15) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_hostel_gender CHECK (gender_type IN ('MALE', 'FEMALE', 'COED'))
) ENGINE=InnoDB;

-- 2. MESSES
CREATE TABLE messes (
    mess_id INT PRIMARY KEY AUTO_INCREMENT,
    mess_name VARCHAR(100) NOT NULL UNIQUE,
    mess_type VARCHAR(20) NOT NULL,
    hostel_id INT NULL,
    capacity INT NOT NULL,
    caterer_name VARCHAR(100) NOT NULL,
    caterer_contact VARCHAR(15) NOT NULL,
    monthly_base_fee DECIMAL(10, 2) NOT NULL,
    per_day_rebate_rate DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_messes_hostel FOREIGN KEY (hostel_id) REFERENCES hostels(hostel_id) ON DELETE SET NULL,
    CONSTRAINT chk_mess_type CHECK (mess_type IN ('PURE_VEG', 'VEG_NON_VEG', 'SPECIAL_DIET')),
    CONSTRAINT chk_mess_capacity CHECK (capacity > 0),
    CONSTRAINT chk_mess_fee CHECK (monthly_base_fee >= 0),
    CONSTRAINT chk_mess_rebate_rate CHECK (per_day_rebate_rate >= 0),
    CONSTRAINT chk_mess_status CHECK (status IN ('ACTIVE', 'UNDER_MAINTENANCE', 'CLOSED'))
) ENGINE=InnoDB;

-- 3. STUDENTS (Name, Registration No, Room No, Veg/Non-Veg preference)
CREATE TABLE students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    registration_no VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    hostel_id INT NOT NULL,
    room_no VARCHAR(10) NOT NULL,
    dietary_preference VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(15) NOT NULL,
    department VARCHAR(50) NOT NULL,
    year_of_study INT NOT NULL,
    emergency_contact VARCHAR(15),
    blood_group VARCHAR(5),
    account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_students_hostel FOREIGN KEY (hostel_id) REFERENCES hostels(hostel_id) ON DELETE RESTRICT,
    CONSTRAINT chk_student_diet CHECK (dietary_preference IN ('VEG', 'NON_VEG', 'JAIN', 'EGG_ONLY')),
    CONSTRAINT chk_student_year CHECK (year_of_study BETWEEN 1 AND 5),
    CONSTRAINT chk_student_status CHECK (account_status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'ALUMNI'))
) ENGINE=InnoDB;

-- 4. MEAL SLOTS
CREATE TABLE meal_slots (
    slot_id INT PRIMARY KEY AUTO_INCREMENT,
    slot_name VARCHAR(20) NOT NULL UNIQUE,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    guest_rate DECIMAL(8, 2) NOT NULL,
    CONSTRAINT chk_slot_name CHECK (slot_name IN ('BREAKFAST', 'LUNCH', 'SNACKS', 'DINNER')),
    CONSTRAINT chk_slot_rate CHECK (guest_rate > 0),
    CONSTRAINT chk_slot_times CHECK (end_time > start_time)
) ENGINE=InnoDB;

-- 5. STUDENT MESS SUBSCRIPTIONS
-- active_student_id is NULL unless status = 'ACTIVE'; its UNIQUE index therefore allows
-- at most ONE active subscription per student (MySQL has no partial unique index).
-- fk_sub_student is RESTRICT because MySQL forbids CASCADE on the base column of a
-- stored generated column; mark leavers ALUMNI/INACTIVE instead of deleting them.
CREATE TABLE student_mess_subscriptions (
    subscription_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    mess_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    plan_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    active_student_id INT GENERATED ALWAYS AS (CASE WHEN status = 'ACTIVE' THEN student_id ELSE NULL END) STORED,
    CONSTRAINT fk_sub_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sub_mess FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    CONSTRAINT chk_sub_plan CHECK (plan_type IN ('MONTHLY', 'SEMESTER', 'ANNUAL')),
    CONSTRAINT chk_sub_status CHECK (status IN ('ACTIVE', 'EXPIRED', 'TRANSFERRED', 'CANCELLED')),
    CONSTRAINT chk_sub_dates CHECK (end_date >= start_date),
    CONSTRAINT uq_one_active_sub UNIQUE (active_student_id)
) ENGINE=InnoDB;

-- 6. WEEKLY MENUS (menu_items is a free-text, comma-separated display string, not a queryable list)
CREATE TABLE weekly_menus (
    menu_id INT PRIMARY KEY AUTO_INCREMENT,
    mess_id INT NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    slot_id INT NOT NULL,
    diet_category VARCHAR(15) NOT NULL,
    menu_items TEXT NOT NULL,
    special_notes VARCHAR(255),
    CONSTRAINT fk_menu_mess FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE CASCADE,
    CONSTRAINT fk_menu_slot FOREIGN KEY (slot_id) REFERENCES meal_slots(slot_id) ON DELETE CASCADE,
    CONSTRAINT chk_menu_day CHECK (day_of_week IN ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')),
    CONSTRAINT chk_menu_diet CHECK (diet_category IN ('VEG', 'NON_VEG', 'COMMON')),
    CONSTRAINT uq_menu UNIQUE (mess_id, day_of_week, slot_id, diet_category)
) ENGINE=InnoDB;

-- 7. MEAL ATTENDANCE
CREATE TABLE meal_attendance (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    mess_id INT NOT NULL,
    slot_id INT NOT NULL,
    attendance_date DATE NOT NULL,
    diet_served VARCHAR(15) NOT NULL,
    verification_type VARCHAR(20) NOT NULL DEFAULT 'RFID',
    scanned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_att_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_att_mess FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    CONSTRAINT fk_att_slot FOREIGN KEY (slot_id) REFERENCES meal_slots(slot_id) ON DELETE RESTRICT,
    CONSTRAINT chk_att_diet CHECK (diet_served IN ('VEG', 'NON_VEG', 'JAIN', 'EGG_ONLY')),
    CONSTRAINT chk_att_verif CHECK (verification_type IN ('RFID', 'BIOMETRIC', 'QR_SCAN', 'MANUAL')),
    CONSTRAINT uq_att UNIQUE (student_id, slot_id, attendance_date)
) ENGINE=InnoDB;

-- 8. MESS REBATES
CREATE TABLE mess_rebates (
    rebate_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'PENDING',
    approved_by VARCHAR(100),
    decision_remarks VARCHAR(255),
    applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rebate_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT chk_rebate_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    CONSTRAINT chk_rebate_dates CHECK (end_date >= start_date)
) ENGINE=InnoDB;

-- 9. MONTHLY BILLS
-- net_payable is a STORED GENERATED column, so it can never drift from its components.
-- rebate_amount stays a stored snapshot (rebate_days x the mess rate AT BILLING TIME).
-- Uniqueness includes mess_id so a mid-month mess transfer can produce two bills.
CREATE TABLE monthly_bills (
    bill_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    mess_id INT NOT NULL,
    billing_month INT NOT NULL,
    billing_year INT NOT NULL,
    base_fee DECIMAL(10, 2) NOT NULL,
    rebate_days INT NOT NULL DEFAULT 0,
    rebate_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    guest_charges DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    fines_or_extras DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    net_payable DECIMAL(10, 2) GENERATED ALWAYS AS (base_fee - rebate_amount + guest_charges + fines_or_extras) STORED,
    payment_status VARCHAR(15) NOT NULL DEFAULT 'UNPAID',
    due_date DATE NOT NULL,
    paid_at DATETIME NULL,
    transaction_reference VARCHAR(50) NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bill_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE RESTRICT,
    CONSTRAINT fk_bill_mess FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    CONSTRAINT chk_bill_month CHECK (billing_month BETWEEN 1 AND 12),
    CONSTRAINT chk_bill_year CHECK (billing_year >= 2020),
    CONSTRAINT chk_bill_base CHECK (base_fee >= 0),
    CONSTRAINT chk_bill_rebate_days CHECK (rebate_days >= 0),
    CONSTRAINT chk_bill_rebate_amt CHECK (rebate_amount >= 0 AND rebate_amount <= base_fee),
    CONSTRAINT chk_bill_guest CHECK (guest_charges >= 0),
    CONSTRAINT chk_bill_fines CHECK (fines_or_extras >= 0),
    CONSTRAINT chk_bill_status CHECK (payment_status IN ('UNPAID', 'PAID', 'OVERDUE', 'WAIVED')),
    CONSTRAINT uq_bill UNIQUE (student_id, mess_id, billing_month, billing_year)
) ENGINE=InnoDB;

-- 10. GUEST MEALS (total_charge is a snapshot of guest_count x guest_rate at booking time)
CREATE TABLE guest_meals (
    guest_meal_id INT PRIMARY KEY AUTO_INCREMENT,
    host_student_id INT NOT NULL,
    mess_id INT NOT NULL,
    slot_id INT NOT NULL,
    booking_date DATE NOT NULL,
    guest_count INT NOT NULL,
    diet_preference VARCHAR(15) NOT NULL,
    total_charge DECIMAL(10, 2) NOT NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'BOOKED',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_guest_student FOREIGN KEY (host_student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_guest_mess FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    CONSTRAINT fk_guest_slot FOREIGN KEY (slot_id) REFERENCES meal_slots(slot_id) ON DELETE RESTRICT,
    CONSTRAINT chk_guest_count CHECK (guest_count > 0),
    CONSTRAINT chk_guest_diet CHECK (diet_preference IN ('VEG', 'NON_VEG')),
    CONSTRAINT chk_guest_charge CHECK (total_charge >= 0),
    CONSTRAINT chk_guest_status CHECK (status IN ('BOOKED', 'CONSUMED', 'CANCELLED'))
) ENGINE=InnoDB;

-- 11. MESS FEEDBACKS
CREATE TABLE mess_feedbacks (
    feedback_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    mess_id INT NOT NULL,
    slot_id INT NULL,
    rating INT NOT NULL,
    category VARCHAR(30) NOT NULL,
    comments TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    action_taken TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fb_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_fb_mess FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    CONSTRAINT fk_fb_slot FOREIGN KEY (slot_id) REFERENCES meal_slots(slot_id) ON DELETE SET NULL,
    CONSTRAINT chk_fb_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT chk_fb_category CHECK (category IN ('FOOD_QUALITY', 'HYGIENE', 'PORTION_SIZE', 'STAFF_BEHAVIOR', 'PUNCTUALITY', 'OTHER')),
    CONSTRAINT chk_fb_status CHECK (status IN ('OPEN', 'UNDER_REVIEW', 'RESOLVED'))
) ENGINE=InnoDB;

-- 12. INVENTORY ITEMS
CREATE TABLE inventory_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    mess_id INT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    category VARCHAR(30) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    current_stock DECIMAL(10, 2) NOT NULL,
    reorder_threshold DECIMAL(10, 2) NOT NULL,
    last_restocked_date DATE,
    CONSTRAINT fk_inv_mess FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE CASCADE,
    CONSTRAINT chk_inv_category CHECK (category IN ('GRAINS_PULSES', 'VEGETABLES', 'DAIRY', 'MEAT_POULTRY', 'SPICES_OIL', 'SNACKS_BEVERAGES', 'CLEANING_OTHERS')),
    CONSTRAINT chk_inv_unit CHECK (unit IN ('KG', 'LITRE', 'PACKET', 'DOZEN', 'UNIT')),
    CONSTRAINT chk_inv_stock CHECK (current_stock >= 0),
    CONSTRAINT chk_inv_reorder CHECK (reorder_threshold >= 0),
    CONSTRAINT uq_inv UNIQUE (mess_id, item_name)
) ENGINE=InnoDB;

-- INDEXES (registration_no / email / names are already indexed via UNIQUE)
CREATE INDEX idx_students_hostel_room ON students(hostel_id, room_no);
CREATE INDEX idx_students_diet ON students(dietary_preference);
CREATE INDEX idx_attendance_date_slot ON meal_attendance(attendance_date, slot_id);
CREATE INDEX idx_attendance_student ON meal_attendance(student_id, attendance_date);
CREATE INDEX idx_rebates_dates ON mess_rebates(start_date, end_date, status);
CREATE INDEX idx_bills_payment_status ON monthly_bills(payment_status);
CREATE INDEX idx_feedback_mess_rating ON mess_feedbacks(mess_id, rating);

-- VIEWS
CREATE VIEW v_active_student_directory AS
SELECT
    s.student_id, s.registration_no, s.full_name, h.hostel_name, h.block_code, s.room_no,
    s.dietary_preference, s.email, s.phone_number, s.department, s.year_of_study,
    m.mess_id, m.mess_name, sub.plan_type,
    sub.start_date AS subscription_start, sub.end_date AS subscription_end
FROM students s
JOIN hostels h ON s.hostel_id = h.hostel_id
LEFT JOIN student_mess_subscriptions sub ON s.student_id = sub.student_id AND sub.status = 'ACTIVE'
LEFT JOIN messes m ON sub.mess_id = m.mess_id
WHERE s.account_status = 'ACTIVE';

CREATE VIEW v_student_billing_summary AS
SELECT
    b.bill_id, s.registration_no, s.full_name,
    CONCAT(h.block_code, '-', s.room_no) AS room_identifier,
    m.mess_name, b.billing_month, b.billing_year, b.base_fee, b.rebate_days, b.rebate_amount,
    b.guest_charges, b.fines_or_extras, b.net_payable, b.payment_status, b.due_date,
    b.paid_at, b.transaction_reference
FROM monthly_bills b
JOIN students s ON b.student_id = s.student_id
JOIN hostels h ON s.hostel_id = h.hostel_id
JOIN messes m ON b.mess_id = m.mess_id;

CREATE VIEW v_mess_ratings_summary AS
SELECT
    m.mess_id, m.mess_name, m.mess_type,
    COUNT(f.feedback_id) AS total_feedbacks,
    ROUND(AVG(f.rating), 2) AS average_rating,
    SUM(CASE WHEN f.rating >= 4 THEN 1 ELSE 0 END) AS positive_reviews_count,
    SUM(CASE WHEN f.rating <= 2 THEN 1 ELSE 0 END) AS complaints_count
FROM messes m
LEFT JOIN mess_feedbacks f ON m.mess_id = f.mess_id
GROUP BY m.mess_id, m.mess_name, m.mess_type;