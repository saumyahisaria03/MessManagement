-- ============================================================================
-- MESS MANAGEMENT SYSTEM - SELF-CONTAINED QUERIES (MySQL 8.0+)
-- Run AFTER schema.sql and seed_data.sql.
--
-- HOW TO USE
--   * Whole file : run the script (Workbench: Ctrl+Shift+Enter).
--   * Single query: copy ONE query block (from its "-- QUERY n" line to its
--     closing ";") into any SQL tab. Every block that needs parameters carries
--     its own SET line(s), so it does not depend on any other block.
--   * IMPORTANT (Workbench): a block has SET + SELECT statements, so SELECT
--     the whole block first and press Ctrl+Shift+Enter. Ctrl+Enter alone runs
--     only the statement under the cursor and the SET would be skipped.
--   * Edit the SET values to look at another day / slot / mess / billing cycle.
--   * Only the very first line (USE) is needed once per tab/connection.
--
-- Header format "-- QUERY n: title" is kept so test_queries.py can parse this
-- file the same way it parses queries.sql.
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
WHERE s.registration_no = '2025BCSE0101';   -- change the registration number here

-- QUERY 2: Kitchen Headcount Demand Forecast (excludes approved leaves and opt-outs)
SET @on_date = CURDATE();   -- date to forecast
SET @slot_id = 2;           -- 1=BREAKFAST 2=LUNCH 3=SNACKS 4=DINNER
SELECT
    m.mess_name,
    d.kitchen_group,
    COUNT(*) AS expected_headcount
FROM v_eligible_diners d
JOIN messes m ON m.mess_id = d.mess_id
WHERE @on_date BETWEEN d.start_date AND d.end_date
  AND NOT EXISTS (SELECT 1 FROM mess_rebates r
                  WHERE r.student_id = d.student_id AND r.status = 'APPROVED'
                    AND @on_date BETWEEN r.start_date AND r.end_date)
  AND NOT EXISTS (SELECT 1 FROM meal_optouts o
                  WHERE o.student_id = d.student_id
                    AND o.meal_date = @on_date AND o.slot_id = @slot_id)
GROUP BY m.mess_name, d.kitchen_group
ORDER BY m.mess_name, d.kitchen_group;

-- QUERY 3: Active Students on Approved Mess Rebate / Leave Today
SET @on_date = CURDATE();   -- day to check
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
  AND @on_date BETWEEN r.start_date AND r.end_date;

-- QUERY 4: Monthly Mess Bill Statement
SET @bill_month = 9, @bill_year = 2026;   -- billing cycle to show
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
WHERE b.billing_month = @bill_month AND b.billing_year = @bill_year
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
    b.due_date,
    DATEDIFF(CURDATE(), b.due_date) AS days_overdue
FROM monthly_bills b
JOIN students s ON b.student_id = s.student_id
JOIN hostels h ON s.hostel_id = h.hostel_id
JOIN messes m ON b.mess_id = m.mess_id
WHERE b.payment_status = 'OVERDUE'
   OR (b.payment_status = 'UNPAID' AND b.due_date < CURDATE())
ORDER BY b.net_payable DESC;

-- QUERY 6: Meal Attendance Log for Lunch Today
SET @on_date = CURDATE();   -- day to check
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
WHERE a.attendance_date = @on_date
  AND ms.slot_name = 'LUNCH'
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

-- QUERY 12: Absenteeism / Meal Skip Detection
SET @on_date = CURDATE();   -- day to check
SET @slot_id = 2;           -- 1=BREAKFAST 2=LUNCH 3=SNACKS 4=DINNER
SET @mess_id = 1;           -- mess to check
SELECT
    d.registration_no,
    d.full_name,
    d.room,
    d.dietary_preference
FROM v_eligible_diners d
WHERE d.mess_id = @mess_id
  AND @on_date BETWEEN d.start_date AND d.end_date
  AND NOT EXISTS (SELECT 1 FROM mess_rebates r
                  WHERE r.student_id = d.student_id AND r.status = 'APPROVED'
                    AND @on_date BETWEEN r.start_date AND r.end_date)
  AND NOT EXISTS (SELECT 1 FROM meal_optouts o
                  WHERE o.student_id = d.student_id
                    AND o.meal_date = @on_date AND o.slot_id = @slot_id)
  AND NOT EXISTS (SELECT 1 FROM meal_attendance a
                  WHERE a.student_id = d.student_id
                    AND a.attendance_date = @on_date AND a.slot_id = @slot_id);

-- QUERY 13: Waste per meal per day (kg, % of cooked food, rupee cost)
SELECT mess_name, production_date, slot_name, diet_category,
       prepared_kg, waste_kg, waste_pct, waste_cost_inr
FROM v_waste_summary
ORDER BY production_date DESC, mess_name, slot_name;

-- QUERY 14: Root cause of waste (which reason costs the most)
SELECT w.reason,
       ROUND(SUM(w.waste_kg), 2) AS total_waste_kg,
       ROUND(SUM(w.waste_kg * p.cost_per_kg), 2) AS cost_inr,
       ROUND(100 * SUM(w.waste_kg) / (SELECT SUM(waste_kg) FROM food_waste_log), 1) AS pct_of_total
FROM food_waste_log w
JOIN meal_production p ON w.production_id = p.production_id
GROUP BY w.reason
ORDER BY total_waste_kg DESC;

-- QUERY 15: Dish-level waste vs student rating (wasted AND disliked = fix the recipe)
SELECT m.mess_name, wm.day_of_week, ms.slot_name, wm.diet_category, wm.menu_items,
       ROUND(wa.waste_kg, 2) AS waste_kg,
       fb.avg_rating, fb.reviews
FROM weekly_menus wm
JOIN messes m ON wm.mess_id = m.mess_id
JOIN meal_slots ms ON wm.slot_id = ms.slot_id
JOIN (SELECT menu_id, SUM(waste_kg) AS waste_kg
      FROM food_waste_log WHERE menu_id IS NOT NULL GROUP BY menu_id) wa ON wa.menu_id = wm.menu_id
LEFT JOIN (SELECT menu_id, ROUND(AVG(rating), 2) AS avg_rating, COUNT(*) AS reviews
           FROM mess_feedbacks WHERE menu_id IS NOT NULL GROUP BY menu_id) fb ON fb.menu_id = wm.menu_id
ORDER BY wa.waste_kg DESC;

-- QUERY 16: Production target (suggested kg to cook)
-- headcount = eligible - approved leaves - opt-outs
-- kg per head = (cooked - wasted) / actual swipes, last 14 days
SET @target_date = CURDATE() + INTERVAL 1 DAY;   -- meal date to plan
SET @target_slot = 2;                              -- 1=BREAKFAST 2=LUNCH 3=SNACKS 4=DINNER
SET @default_kg_per_head = 0.35;                   -- fallback if no history anywhere
WITH waste AS (
    SELECT production_id, SUM(waste_kg) AS waste_kg FROM food_waste_log GROUP BY production_id
),
prod_actual AS (
    SELECT p.mess_id, p.slot_id, p.diet_category,
           p.prepared_kg - COALESCE(w.waste_kg, 0) AS eaten_kg,
           (SELECT COUNT(*) FROM meal_attendance a
              JOIN diet_map dm ON dm.dietary_preference = a.diet_served
             WHERE a.mess_id = p.mess_id AND a.slot_id = p.slot_id
               AND a.attendance_date = p.production_date
               AND dm.kitchen_group = p.diet_category) AS swipes
    FROM meal_production p
    LEFT JOIN waste w ON w.production_id = p.production_id
    WHERE p.production_date >= CURDATE() - INTERVAL 14 DAY
),
hist AS (
    SELECT mess_id, slot_id, diet_category, SUM(eaten_kg) / SUM(swipes) AS net_kg_per_head
    FROM prod_actual WHERE swipes > 0
    GROUP BY mess_id, slot_id, diet_category
),
global_hist AS (
    SELECT slot_id, diet_category, SUM(eaten_kg) / SUM(swipes) AS net_kg_per_head
    FROM prod_actual WHERE swipes > 0
    GROUP BY slot_id, diet_category
),
demand AS (
    SELECT d.mess_id, d.kitchen_group AS diet_group, COUNT(*) AS headcount
    FROM v_eligible_diners d
    WHERE @target_date BETWEEN d.start_date AND d.end_date
      AND NOT EXISTS (SELECT 1 FROM mess_rebates r
                      WHERE r.student_id = d.student_id AND r.status = 'APPROVED'
                        AND @target_date BETWEEN r.start_date AND r.end_date)
      AND NOT EXISTS (SELECT 1 FROM meal_optouts o
                      WHERE o.student_id = d.student_id
                        AND o.meal_date = @target_date AND o.slot_id = @target_slot)
    GROUP BY d.mess_id, d.kitchen_group
)
SELECT m.mess_name, dm.diet_group, dm.headcount,
       ROUND(COALESCE(h.net_kg_per_head, g.net_kg_per_head, @default_kg_per_head), 3) AS kg_per_head,
       CASE WHEN h.net_kg_per_head IS NOT NULL THEN 'mess history'
            WHEN g.net_kg_per_head IS NOT NULL THEN 'all-mess average'
            ELSE 'default' END AS basis,
       ROUND(dm.headcount * COALESCE(h.net_kg_per_head, g.net_kg_per_head, @default_kg_per_head), 2) AS suggested_kg_to_cook
FROM demand dm
JOIN messes m ON m.mess_id = dm.mess_id
LEFT JOIN hist h ON h.mess_id = dm.mess_id AND h.diet_category = dm.diet_group AND h.slot_id = @target_slot
LEFT JOIN global_hist g ON g.diet_category = dm.diet_group AND g.slot_id = @target_slot
ORDER BY m.mess_name, dm.diet_group;

-- QUERY 17: Weekly waste trend per mess (is it going down?)
SELECT mess_name,
       YEARWEEK(production_date, 1) AS year_week,
       ROUND(SUM(prepared_kg), 2) AS cooked_kg,
       ROUND(SUM(waste_kg), 2) AS wasted_kg,
       ROUND(100 * SUM(waste_kg) / SUM(prepared_kg), 1) AS waste_pct,
       ROUND(SUM(waste_cost_inr), 2) AS cost_inr
FROM v_waste_summary
GROUP BY mess_name, YEARWEEK(production_date, 1)
ORDER BY mess_name, year_week;

-- QUERY 18: Feedback action list - dishes students leave on the plate
SELECT m.mess_name, wm.menu_items,
       COUNT(*) AS responses,
       SUM(f.plate_left IN ('HALF', 'MOST')) AS heavy_leftover_reports,
       ROUND(AVG(f.rating), 2) AS avg_rating
FROM mess_feedbacks f
JOIN weekly_menus wm ON f.menu_id = wm.menu_id
JOIN messes m ON wm.mess_id = m.mess_id
WHERE f.plate_left IS NOT NULL
GROUP BY wm.menu_id, m.mess_name, wm.menu_items
HAVING heavy_leftover_reports >= 1
ORDER BY heavy_leftover_reports DESC;

-- QUERY 19: Data-integrity audit (every row here is a bad record; expect 0 rows)
SELECT 'WASTE_EXCEEDS_COOKED' AS issue, p.production_id AS ref_id
FROM meal_production p
JOIN food_waste_log w ON w.production_id = p.production_id
GROUP BY p.production_id, p.prepared_kg
HAVING SUM(w.waste_kg) > p.prepared_kg
UNION ALL
SELECT 'WASTE_MENU_MISMATCH', w.waste_id
FROM food_waste_log w
JOIN meal_production p ON w.production_id = p.production_id
JOIN weekly_menus wm ON w.menu_id = wm.menu_id
WHERE wm.mess_id <> p.mess_id OR wm.slot_id <> p.slot_id
UNION ALL
SELECT 'OPTOUT_NOT_SUBSCRIBED', o.optout_id
FROM meal_optouts o
LEFT JOIN student_mess_subscriptions sub
       ON sub.student_id = o.student_id AND sub.mess_id = o.mess_id
      AND sub.status = 'ACTIVE' AND o.meal_date BETWEEN sub.start_date AND sub.end_date
WHERE sub.subscription_id IS NULL;
