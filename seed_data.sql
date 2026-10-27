-- ============================================================================
-- MESS MANAGEMENT SYSTEM SEED DATA (MySQL)
-- Run AFTER schema.sql
-- Attendance, current leaves and the upcoming guest booking are dated RELATIVE TO
-- CURDATE(), so the "today" queries always return data. Billing rows are a fixed
-- historical cycle (September 2026).
-- ============================================================================
USE mess_management;

-- 1. Hostels
INSERT INTO hostels (hostel_id, hostel_name, block_code, gender_type, warden_name, warden_contact) VALUES
(1, 'Aryabhata Boys Hostel', 'BH-1', 'MALE', 'Dr. Ramesh Sharma', '+91-9876543210'),
(2, 'CV Raman Boys Hostel', 'BH-2', 'MALE', 'Prof. Arvind Menon', '+91-9876543211'),
(3, 'Kalpana Chawla Girls Hostel', 'GH-1', 'FEMALE', 'Dr. Sunita Deshmukh', '+91-9876543212'),
(4, 'Gargi Girls Hostel', 'GH-2', 'FEMALE', 'Prof. Meenakshi Sundaram', '+91-9876543213');

-- 2. Messes
INSERT INTO messes (mess_id, mess_name, mess_type, hostel_id, capacity, caterer_name, caterer_contact, monthly_base_fee, per_day_rebate_rate, status) VALUES
(1, 'Central Dining Hall - North Mess', 'VEG_NON_VEG', 1, 400, 'Annapurna Hospitality Services', '+91-9123456780', 4200.00, 110.00, 'ACTIVE'),
(2, 'Kaveri Dining Hall - South Mess', 'PURE_VEG', 2, 350, 'Shree Krishna Caterers', '+91-9123456781', 3800.00, 100.00, 'ACTIVE'),
(3, 'Pragati Dining Hall - Multi-Cuisine', 'VEG_NON_VEG', 3, 450, 'Royal Feast Caterers', '+91-9123456782', 4400.00, 115.00, 'ACTIVE');

-- 3. Meal Slots
INSERT INTO meal_slots (slot_id, slot_name, start_time, end_time, guest_rate) VALUES
(1, 'BREAKFAST', '07:30:00', '09:30:00', 50.00),
(2, 'LUNCH', '12:00:00', '14:15:00', 90.00),
(3, 'SNACKS', '17:00:00', '18:15:00', 35.00),
(4, 'DINNER', '19:30:00', '21:45:00', 95.00);

-- 4. Students (registration year = 2026 - year_of_study + 1)
INSERT INTO students (student_id, registration_no, full_name, hostel_id, room_no, dietary_preference, email, phone_number, department, year_of_study, emergency_contact, blood_group, account_status) VALUES
(1, '2025BCSE0101', 'Aarav Sharma', 1, 'B-204', 'NON_VEG', 'aarav.sharma@univ.edu', '+91-9811122331', 'Computer Science & Engineering', 2, '+91-9911122331', 'B+', 'ACTIVE'),
(2, '2025BCSE0102', 'Priya Patel', 3, 'G-108', 'VEG', 'priya.patel@univ.edu', '+91-9811122332', 'Computer Science & Engineering', 2, '+91-9911122332', 'O+', 'ACTIVE'),
(3, '2024BECE0045', 'Rohan Kulkarni', 1, 'B-312', 'VEG', 'rohan.k@univ.edu', '+91-9811122333', 'Electronics & Comm Engineering', 3, '+91-9911122333', 'A+', 'ACTIVE'),
(4, '2024BMEE0089', 'Vikram Singh Rathore', 2, 'C-105', 'NON_VEG', 'vikram.rathore@univ.edu', '+91-9811122334', 'Mechanical Engineering', 3, '+91-9911122334', 'AB+', 'ACTIVE'),
(5, '2026BCIV0012', 'Ananya Iyer', 3, 'G-305', 'JAIN', 'ananya.iyer@univ.edu', '+91-9811122335', 'Civil Engineering', 1, '+91-9911122335', 'O-', 'ACTIVE'),
(6, '2025BCHE0034', 'Mohammad Tariq', 2, 'C-410', 'NON_VEG', 'tariq.m@univ.edu', '+91-9811122336', 'Chemical Engineering', 2, '+91-9911122336', 'B-', 'ACTIVE'),
(7, '2023BCSE0008', 'Sneha Sen', 4, 'D-215', 'EGG_ONLY', 'sneha.sen@univ.edu', '+91-9811122337', 'Computer Science & Engineering', 4, '+91-9911122337', 'A-', 'ACTIVE'),
(8, '2026BECE0078', 'Devendra Joshi', 1, 'B-101', 'VEG', 'devendra.j@univ.edu', '+91-9811122338', 'Electronics & Comm Engineering', 1, '+91-9911122338', 'O+', 'ACTIVE'),
(9, '2024BIT0022', 'Tanvi Reddy', 3, 'G-214', 'NON_VEG', 'tanvi.reddy@univ.edu', '+91-9811122339', 'Information Technology', 3, '+91-9911122339', 'B+', 'ACTIVE'),
(10, '2025BMEE0054', 'Gurpreet Singh', 2, 'C-220', 'NON_VEG', 'gurpreet.s@univ.edu', '+91-9811122340', 'Mechanical Engineering', 2, '+91-9911122340', 'A+', 'ACTIVE');

-- 5. Subscriptions (one ACTIVE row per student is enforced by uq_one_active_sub)
INSERT INTO student_mess_subscriptions (subscription_id, student_id, mess_id, start_date, end_date, plan_type, status) VALUES
(1, 1, 1, '2026-08-01', '2026-12-31', 'SEMESTER', 'ACTIVE'),
(2, 2, 3, '2026-08-01', '2026-12-31', 'SEMESTER', 'ACTIVE'),
(3, 3, 2, '2026-08-01', '2026-12-31', 'SEMESTER', 'ACTIVE'),
(4, 4, 1, '2026-08-01', '2026-12-31', 'SEMESTER', 'ACTIVE'),
(5, 5, 2, '2026-08-01', '2026-12-31', 'SEMESTER', 'ACTIVE'),
(6, 6, 1, '2026-08-01', '2026-12-31', 'SEMESTER', 'ACTIVE'),
(7, 7, 3, '2026-08-01', '2026-12-31', 'SEMESTER', 'ACTIVE'),
(8, 8, 2, '2026-08-01', '2026-12-31', 'SEMESTER', 'ACTIVE'),
(9, 9, 3, '2026-08-01', '2026-12-31', 'SEMESTER', 'ACTIVE'),
(10, 10, 1, '2026-08-01', '2026-12-31', 'SEMESTER', 'ACTIVE');

-- 6. Weekly Menus
INSERT INTO weekly_menus (mess_id, day_of_week, slot_id, diet_category, menu_items, special_notes) VALUES
(1, 'MONDAY', 1, 'COMMON', 'Aloo Paratha, Curd, Pickle, Tea, Coffee, Bread-Butter, Bananas', 'Standard Breakfast'),
(1, 'MONDAY', 2, 'COMMON', 'Steamed Rice, Chapatis, Dal Tadka, Salad, Gulab Jamun', 'Daily Lunch Base'),
(1, 'MONDAY', 2, 'VEG', 'Shahi Paneer, Mix Veg Korma', 'Vegetarian Main'),
(1, 'MONDAY', 2, 'NON_VEG', 'Chicken Curry, Boiled Eggs', 'Non-Veg Special Counter'),
(1, 'MONDAY', 3, 'COMMON', 'Samosa, Mint Chutney, Masala Chai, Biscuits', 'Evening Snack'),
(1, 'MONDAY', 4, 'COMMON', 'Jeera Rice, Chapatis, Dal Makhani, Papad, Kheer', 'Dinner Base'),
(1, 'MONDAY', 4, 'VEG', 'Malai Kofta, Bhindi Do Pyaza', 'Vegetarian Main'),
(1, 'MONDAY', 4, 'NON_VEG', 'Egg Curry, Chicken Sukka', 'Non-Veg Option'),
(1, 'TUESDAY', 1, 'COMMON', 'Poha, Sev, Boiled Sprouts, Jalebi, Milk, Tea, Toast', 'Breakfast'),
(1, 'TUESDAY', 2, 'COMMON', 'Veg Biryani, Plain Rice, Raita, Yellow Dal, Roti', 'Lunch Common'),
(1, 'TUESDAY', 2, 'VEG', 'Mushroom Masala, Baingan Bharta', 'Veg Lunch Item'),
(1, 'TUESDAY', 2, 'NON_VEG', 'Mutton Curry (Alternate weeks) / Chicken Masala', 'Non-Veg Lunch Item'),
(1, 'TUESDAY', 3, 'COMMON', 'Veg Cutlet, Tomato Sauce, Ginger Tea', 'Snacks'),
(1, 'TUESDAY', 4, 'COMMON', 'Phulka, Basmati Rice, Dal Fry, Ice Cream', 'Dinner Common'),
(1, 'TUESDAY', 4, 'VEG', 'Paneer Butter Masala, Aloo Gobi', 'Veg Dinner'),
(1, 'TUESDAY', 4, 'NON_VEG', 'Fish Curry, Tawa Egg Bhurji', 'Non-Veg Dinner'),
(2, 'WEDNESDAY', 1, 'COMMON', 'Idli, Medu Vada, Coconut Chutney, Sambar, Filter Coffee', 'Traditional South Indian'),
(2, 'WEDNESDAY', 2, 'COMMON', 'Boiled Ponni Rice, Sambar, Rasam, Curd, Appalam, Payasam', 'South Indian Lunch Thali'),
(2, 'WEDNESDAY', 2, 'VEG', 'Poriyal (Cabbage/Carrot), Paneer Chettinad', 'Veg Accompaniments'),
(2, 'WEDNESDAY', 3, 'COMMON', 'Mysore Bonda, Chutney, Tea, Coffee', 'Evening Snack'),
(2, 'WEDNESDAY', 4, 'COMMON', 'Dosa, Chutney Trio, Sambar, Lemon Rice, Roti, Dal', 'Dinner');

-- 7. Meal Attendance (yesterday = CURDATE() - 1 day, today = CURDATE())
-- Student 10 (mess 1) deliberately has NO lunch swipe today so Query 12 returns a row.
INSERT INTO meal_attendance (attendance_id, student_id, mess_id, slot_id, attendance_date, diet_served, verification_type, scanned_at) VALUES
(1, 1, 1, 1, CURDATE() - INTERVAL 1 DAY, 'NON_VEG', 'RFID', TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '08:05:12')),
(2, 1, 1, 2, CURDATE() - INTERVAL 1 DAY, 'NON_VEG', 'RFID', TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '12:45:30')),
(3, 1, 1, 4, CURDATE() - INTERVAL 1 DAY, 'NON_VEG', 'RFID', TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '20:10:04')),
(4, 2, 3, 1, CURDATE() - INTERVAL 1 DAY, 'VEG', 'BIOMETRIC', TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '08:30:22')),
(5, 2, 3, 2, CURDATE() - INTERVAL 1 DAY, 'VEG', 'BIOMETRIC', TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '13:10:15')),
(6, 2, 3, 4, CURDATE() - INTERVAL 1 DAY, 'VEG', 'BIOMETRIC', TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '20:30:45')),
(7, 3, 2, 2, CURDATE() - INTERVAL 1 DAY, 'VEG', 'QR_SCAN', TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '13:00:10')),
(8, 4, 1, 2, CURDATE() - INTERVAL 1 DAY, 'NON_VEG', 'RFID', TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '13:20:00')),
(9, 6, 1, 2, CURDATE() - INTERVAL 1 DAY, 'NON_VEG', 'RFID', TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '12:50:18')),
(10, 8, 2, 2, CURDATE() - INTERVAL 1 DAY, 'VEG', 'BIOMETRIC', TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '13:15:00')),
(11, 1, 1, 1, CURDATE(), 'NON_VEG', 'RFID', TIMESTAMP(CURDATE(), '08:15:00')),
(12, 1, 1, 2, CURDATE(), 'NON_VEG', 'RFID', TIMESTAMP(CURDATE(), '13:05:00')),
(13, 2, 3, 1, CURDATE(), 'VEG', 'BIOMETRIC', TIMESTAMP(CURDATE(), '08:45:00')),
(14, 2, 3, 2, CURDATE(), 'VEG', 'BIOMETRIC', TIMESTAMP(CURDATE(), '13:10:00')),
(15, 6, 1, 1, CURDATE(), 'NON_VEG', 'RFID', TIMESTAMP(CURDATE(), '08:20:00')),
(16, 6, 1, 2, CURDATE(), 'NON_VEG', 'RFID', TIMESTAMP(CURDATE(), '12:55:00')),
(17, 8, 2, 1, CURDATE(), 'VEG', 'BIOMETRIC', TIMESTAMP(CURDATE(), '08:35:00')),
(18, 8, 2, 2, CURDATE(), 'VEG', 'BIOMETRIC', TIMESTAMP(CURDATE(), '13:05:00'));

-- 8. Mess Rebates (1-3 are relative to today; 4-5 are historical)
-- Rule used in the remarks: personal leave needs >= 5 consecutive days; official duty leave is exempt.
INSERT INTO mess_rebates (rebate_id, student_id, start_date, end_date, reason, status, approved_by, decision_remarks, applied_at) VALUES
(1, 3, CURDATE(), CURDATE() + INTERVAL 5 DAY, 'Going home for family function and festival', 'APPROVED', 'Dr. Ramesh Sharma', 'Leave granted as per university rules', TIMESTAMP(CURDATE() - INTERVAL 3 DAY, '14:00:00')),
(2, 4, CURDATE(), CURDATE() + INTERVAL 3 DAY, 'Attending Inter-IIT Sports Meet in Delhi', 'APPROVED', 'Prof. Arvind Menon', 'Official sports representation approved (duty leave, minimum-days rule waived)', TIMESTAMP(CURDATE() - INTERVAL 4 DAY, '11:30:00')),
(3, 5, CURDATE() + INTERVAL 7 DAY, CURDATE() + INTERVAL 12 DAY, 'Medical rest prescribed by campus physician', 'PENDING', NULL, NULL, TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '16:45:00')),
(4, 7, '2026-09-10', '2026-09-15', 'Attending National Hackathon Conference', 'APPROVED', 'Prof. Meenakshi Sundaram', 'Academic representation verified', '2026-09-05 09:15:00'),
(5, 9, '2026-09-18', '2026-09-21', 'Personal leave', 'REJECTED', 'Dr. Sunita Deshmukh', 'Personal leave requires at least 5 consecutive days', '2026-09-16 10:00:00');

-- 9. Monthly Bills (September 2026). net_payable is generated by the schema, so it is NOT inserted.
INSERT INTO monthly_bills (bill_id, student_id, mess_id, billing_month, billing_year, base_fee, rebate_days, rebate_amount, guest_charges, fines_or_extras, payment_status, due_date, paid_at, transaction_reference) VALUES
(1, 1, 1, 9, 2026, 4200.00, 0, 0.00, 180.00, 0.00, 'PAID', '2026-10-10', '2026-10-05 14:22:10', 'UPI/20261005142210/SBI01'),
(2, 2, 3, 9, 2026, 4400.00, 0, 0.00, 0.00, 0.00, 'PAID', '2026-10-10', '2026-10-07 19:40:02', 'HDFC/NETB/992817462'),
(3, 3, 2, 9, 2026, 3800.00, 0, 0.00, 90.00, 0.00, 'PAID', '2026-10-10', '2026-10-08 11:15:43', 'ICICI/UPI/772183912'),
(4, 7, 3, 9, 2026, 4400.00, 6, 690.00, 0.00, 0.00, 'PAID', '2026-10-10', '2026-10-06 16:02:11', 'PAYTM/UPI/884910294'),
(5, 4, 1, 9, 2026, 4200.00, 0, 0.00, 0.00, 150.00, 'OVERDUE', '2026-10-10', NULL, NULL),
(6, 6, 1, 9, 2026, 4200.00, 0, 0.00, 0.00, 0.00, 'PAID', '2026-10-10', '2026-10-09 21:05:33', 'AXIS/NETB/334910284'),
(7, 10, 1, 9, 2026, 4200.00, 0, 0.00, 95.00, 0.00, 'OVERDUE', '2026-10-10', NULL, NULL),
(8, 5, 2, 9, 2026, 3800.00, 0, 0.00, 0.00, 0.00, 'PAID', '2026-10-10', '2026-10-04 10:12:09', 'UPI/20261004101209/HDF02'),
(9, 8, 2, 9, 2026, 3800.00, 0, 0.00, 0.00, 0.00, 'PAID', '2026-10-10', '2026-10-09 18:45:51', 'UPI/20261009184551/AXS03'),
(10, 9, 3, 9, 2026, 4400.00, 0, 0.00, 0.00, 0.00, 'OVERDUE', '2026-10-10', NULL, NULL);

-- 10. Guest Meals (booking 4 is tomorrow, relative to today)
INSERT INTO guest_meals (guest_meal_id, host_student_id, mess_id, slot_id, booking_date, guest_count, diet_preference, total_charge, status) VALUES
(1, 1, 1, 2, '2026-09-15', 2, 'NON_VEG', 180.00, 'CONSUMED'),
(2, 3, 2, 2, '2026-09-20', 1, 'VEG', 90.00, 'CONSUMED'),
(3, 10, 1, 4, '2026-09-28', 1, 'NON_VEG', 95.00, 'CONSUMED'),
(4, 2, 3, 2, CURDATE() + INTERVAL 1 DAY, 2, 'VEG', 180.00, 'BOOKED');

-- 11. Feedback
INSERT INTO mess_feedbacks (feedback_id, student_id, mess_id, slot_id, rating, category, comments, status, action_taken) VALUES
(1, 1, 1, 4, 4, 'FOOD_QUALITY', 'Dinner paneer was fresh and delicious. Chicken portion was generous.', 'RESOLVED', 'Feedback shared with executive chef'),
(2, 3, 2, 1, 5, 'HYGIENE', 'Dining tables and washing area are remarkably neat and clean.', 'RESOLVED', 'Appreciation noted for housekeeping team'),
(3, 4, 1, 2, 2, 'PORTION_SIZE', 'Non-veg chicken pieces were very small and ran out before 1:45 PM.', 'OPEN', 'Under inspection by mess committee'),
(4, 2, 3, 3, 4, 'FOOD_QUALITY', 'Snacks tea and samosas were warm and crispy.', 'RESOLVED', 'Noted'),
(5, 6, 1, 4, 2, 'PUNCTUALITY', 'Dinner serving started 20 minutes late causing a long queue.', 'UNDER_REVIEW', 'Caterer issued formal advisory note');

-- 12. Inventory (items 3, 4 and 8 are below reorder threshold)
INSERT INTO inventory_items (item_id, mess_id, item_name, category, unit, current_stock, reorder_threshold, last_restocked_date) VALUES
(1, 1, 'Basmati Rice', 'GRAINS_PULSES', 'KG', 450.00, 100.00, '2026-10-08'),
(2, 1, 'Toor Dal', 'GRAINS_PULSES', 'KG', 120.00, 50.00, '2026-10-08'),
(3, 1, 'Fresh Paneer', 'DAIRY', 'KG', 25.00, 30.00, '2026-10-12'),
(4, 1, 'Chicken (Broiler)', 'MEAT_POULTRY', 'KG', 18.00, 40.00, '2026-10-12'),
(5, 1, 'Refined Sunflower Oil', 'SPICES_OIL', 'LITRE', 85.00, 30.00, '2026-10-05'),
(6, 2, 'Sona Masoori Rice', 'GRAINS_PULSES', 'KG', 380.00, 80.00, '2026-10-09'),
(7, 2, 'Urad Dal', 'GRAINS_PULSES', 'KG', 90.00, 35.00, '2026-10-09'),
(8, 2, 'Cow Milk', 'DAIRY', 'LITRE', 45.00, 50.00, '2026-10-13');