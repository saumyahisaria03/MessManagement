-- ============================================================================
-- MESS MANAGEMENT SYSTEM BUSINESS & ANALYTICAL QUERIES (MySQL)
-- Run AFTER schema.sql and seed_data.sql
-- In Workbench: place the cursor inside a query and press Ctrl+Enter to run it.
-- ============================================================================
USE mess_management;

-- QUERY 1: Student Profile Lookup by Registration Number
SELECT
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
    m.mess_name AS subscribed_mess,
    sub.plan_type AS subscription_plan
FROM students s
JOIN hostels h ON s.hostel_id = h.hostel_id
LEFT JOIN student_mess_subscriptions sub ON s.student_id = sub.student_id AND sub.status = 'ACTIVE'
LEFT JOIN messes m ON sub.mess_id = m.mess_id
WHERE s.registration_no = '2023BCSE0101';

-- QUERY 2: Kitchen Headcount Demand Forecast (excludes approved leaves)
SELECT
    m.mess_name,
    s.dietary_preference,
    COUNT(s.student_id) AS expected_headcount
FROM student_mess_subscriptions sub
JOIN messes m ON sub.mess_id = m.mess_id
JOIN students s ON sub.student_id = s.student_id
WHERE sub.status = 'ACTIVE'
  AND s.account_status = 'ACTIVE'
  AND s.student_id NOT IN (
      SELECT student_id
      FROM mess_rebates
      WHERE status = 'APPROVED'
        AND '2026-10-13' BETWEEN start_date AND end_date
  )
GROUP BY m.mess_name, s.dietary_preference
ORDER BY m.mess_name, s.dietary_preference;

-- QUERY 3: Active Students on Approved Mess Rebate / Leave Today
SELECT
    r.rebate_id,
    s.registration_no,
    s.full_name,
    CONCAT(h.block_code, '-', s.room_no) AS room_location,
    s.dietary_preference,
    r.start_date,
    r.end_date,
    DATEDIFF(r.end_date, r.start_date) + 1 AS leave_days,
    r.reason,
    r.approved_by
FROM mess_rebates r
JOIN students s ON r.student_id = s.student_id
JOIN hostels h ON s.hostel_id = h.hostel_id
WHERE r.status = 'APPROVED'
  AND '2026-10-13' BETWEEN r.start_date AND r.end_date;

-- QUERY 4: Monthly Mess Bill Statement (September 2026)
SELECT
    b.bill_id,
    s.registration_no,
    s.full_name,
    h.block_code,
    s.room_no,
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
    b.due_date
FROM monthly_bills b
JOIN students s ON b.student_id = s.student_id
JOIN hostels h ON s.hostel_id = h.hostel_id
JOIN messes m ON b.mess_id = m.mess_id
WHERE b.billing_month = 9 AND b.billing_year = 2026
ORDER BY b.net_payable DESC;

-- QUERY 5: Fee Defaulter / Overdue Payment Tracking
SELECT
    s.registration_no,
    s.full_name,
    h.hostel_name,
    s.room_no,
    s.phone_number,
    m.mess_name,
    b.billing_month,
    b.billing_year,
    b.net_payable AS outstanding_amount,
    b.due_date
FROM monthly_bills b
JOIN students s ON b.student_id = s.student_id
JOIN hostels h ON s.hostel_id = h.hostel_id
JOIN messes m ON b.mess_id = m.mess_id
WHERE b.payment_status = 'OVERDUE'
ORDER BY b.net_payable DESC;

-- QUERY 6: Meal Attendance Log for Lunch on 2026-10-13
SELECT
    a.attendance_id,
    s.registration_no,
    s.full_name,
    CONCAT(h.block_code, '-', s.room_no) AS room,
    m.mess_name,
    ms.slot_name,
    a.diet_served,
    a.verification_type,
    a.scanned_at
FROM meal_attendance a
JOIN students s ON a.student_id = s.student_id
JOIN hostels h ON s.hostel_id = h.hostel_id
JOIN messes m ON a.mess_id = m.mess_id
JOIN meal_slots ms ON a.slot_id = ms.slot_id
WHERE a.attendance_date = '2026-10-13' AND ms.slot_name = 'LUNCH'
ORDER BY a.scanned_at ASC;

-- QUERY 7: Weekly Menu Schedule for Monday (Mess 1)
SELECT
    m.mess_name,
    ms.slot_name,
    wm.diet_category,
    wm.menu_items,
    wm.special_notes
FROM weekly_menus wm
JOIN messes m ON wm.mess_id = m.mess_id
JOIN meal_slots ms ON wm.slot_id = ms.slot_id
WHERE wm.day_of_week = 'MONDAY' AND m.mess_id = 1
ORDER BY ms.slot_id, wm.diet_category;

-- QUERY 8: Veg vs Non-Veg Distribution Across Hostels
SELECT
    h.hostel_name,
    h.block_code,
    COUNT(s.student_id) AS total_students,
    SUM(CASE WHEN s.dietary_preference = 'VEG' THEN 1 ELSE 0 END) AS veg_count,
    SUM(CASE WHEN s.dietary_preference = 'NON_VEG' THEN 1 ELSE 0 END) AS non_veg_count,
    SUM(CASE WHEN s.dietary_preference = 'JAIN' THEN 1 ELSE 0 END) AS jain_count,
    SUM(CASE WHEN s.dietary_preference = 'EGG_ONLY' THEN 1 ELSE 0 END) AS egg_only_count
FROM hostels h
LEFT JOIN students s ON h.hostel_id = s.hostel_id
GROUP BY h.hostel_id, h.hostel_name, h.block_code
ORDER BY h.hostel_id;

-- QUERY 9: Critical Low Stock Kitchen Inventory Alerts
SELECT
    m.mess_name,
    i.item_name,
    i.category,
    i.current_stock,
    i.reorder_threshold,
    i.unit,
    (i.reorder_threshold - i.current_stock) AS shortfall,
    i.last_restocked_date
FROM inventory_items i
JOIN messes m ON i.mess_id = m.mess_id
WHERE i.current_stock <= i.reorder_threshold
ORDER BY shortfall DESC;

-- QUERY 10: Mess Quality & Hygiene Ratings Dashboard
SELECT
    m.mess_name,
    m.caterer_name,
    COUNT(f.feedback_id) AS total_reviews,
    ROUND(AVG(f.rating), 2) AS average_score,
    SUM(CASE WHEN f.category = 'FOOD_QUALITY' THEN 1 ELSE 0 END) AS food_quality_issues,
    SUM(CASE WHEN f.category = 'HYGIENE' THEN 1 ELSE 0 END) AS hygiene_issues,
    SUM(CASE WHEN f.category = 'PORTION_SIZE' THEN 1 ELSE 0 END) AS portion_issues,
    SUM(CASE WHEN f.status = 'OPEN' THEN 1 ELSE 0 END) AS pending_action_count
FROM messes m
LEFT JOIN mess_feedbacks f ON m.mess_id = f.mess_id
GROUP BY m.mess_id, m.mess_name, m.caterer_name;

-- QUERY 11: Guest Meals Consumption and Revenue Report
SELECT
    m.mess_name,
    gm.diet_preference,
    SUM(gm.guest_count) AS total_guests_served,
    SUM(gm.total_charge) AS total_revenue_inr
FROM guest_meals gm
JOIN messes m ON gm.mess_id = m.mess_id
WHERE gm.status = 'CONSUMED'
GROUP BY m.mess_name, gm.diet_preference;

-- QUERY 12: Absenteeism / Meal Skip Detection (Central Mess lunch, 2026-10-13)
SELECT
    s.registration_no,
    s.full_name,
    CONCAT(h.block_code, '-', s.room_no) AS room,
    s.dietary_preference
FROM student_mess_subscriptions sub
JOIN students s ON sub.student_id = s.student_id
JOIN hostels h ON s.hostel_id = h.hostel_id
WHERE sub.mess_id = 1
  AND sub.status = 'ACTIVE'
  AND s.student_id NOT IN (
      SELECT student_id FROM mess_rebates
      WHERE status = 'APPROVED' AND '2026-10-13' BETWEEN start_date AND end_date
  )
  AND s.student_id NOT IN (
      SELECT student_id FROM meal_attendance
      WHERE attendance_date = '2026-10-13' AND slot_id = 2
  );