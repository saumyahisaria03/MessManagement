-- ============================================================================
-- FOOD WASTE CONTROL + FEEDBACK MODULE (MySQL 8.0.16+)
-- Run AFTER schema.sql and seed_data.sql. Not re-runnable (ALTER statements);
-- to re-run, rebuild from schema.sql first. When happy, merge the sections into
-- schema.sql / seed_data.sql / queries.sql.
--
-- Loop:  PREDICT (headcount - leaves - opt-outs)  ->  MEASURE (production + waste log)
--        ->  LEARN (dish-level feedback + plate leftover)  ->  ACT (queries 13-18)
-- ============================================================================
USE mess_management;

-- ---------------------------------------------------------------------------
-- A. DDL
-- ---------------------------------------------------------------------------

-- A1. Students declare in advance that they will skip a meal -> kitchen cooks less.
CREATE TABLE meal_optouts (
    optout_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    mess_id INT NOT NULL,
    slot_id INT NOT NULL,
    meal_date DATE NOT NULL,
    reason VARCHAR(15) NOT NULL DEFAULT 'OTHER',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_optout_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_optout_mess FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    CONSTRAINT fk_optout_slot FOREIGN KEY (slot_id) REFERENCES meal_slots(slot_id) ON DELETE RESTRICT,
    CONSTRAINT chk_optout_reason CHECK (reason IN ('ACADEMIC', 'EATING_OUT', 'OTHER')),
    CONSTRAINT uq_optout UNIQUE (student_id, slot_id, meal_date)
) ENGINE=InnoDB;

-- A2. What the kitchen actually cooked, per mess / date / meal / diet line.
CREATE TABLE meal_production (
    production_id INT PRIMARY KEY AUTO_INCREMENT,
    mess_id INT NOT NULL,
    slot_id INT NOT NULL,
    production_date DATE NOT NULL,
    diet_category VARCHAR(15) NOT NULL,
    planned_headcount INT NOT NULL,
    prepared_kg DECIMAL(8, 2) NOT NULL,
    cost_per_kg DECIMAL(8, 2) NOT NULL,
    prepared_by VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_prod_mess FOREIGN KEY (mess_id) REFERENCES messes(mess_id) ON DELETE RESTRICT,
    CONSTRAINT fk_prod_slot FOREIGN KEY (slot_id) REFERENCES meal_slots(slot_id) ON DELETE RESTRICT,
    CONSTRAINT chk_prod_diet CHECK (diet_category IN ('VEG', 'NON_VEG', 'COMMON')),
    CONSTRAINT chk_prod_headcount CHECK (planned_headcount >= 0),
    CONSTRAINT chk_prod_kg CHECK (prepared_kg > 0),
    CONSTRAINT chk_prod_cost CHECK (cost_per_kg >= 0),
    CONSTRAINT uq_production UNIQUE (mess_id, slot_id, production_date, diet_category)
) ENGINE=InnoDB;

-- A3. Waste entries for a production batch: where, why and how much. menu_id is optional
-- and enables dish-level waste (joins to weekly_menus and to feedback).
CREATE TABLE food_waste_log (
    waste_id INT PRIMARY KEY AUTO_INCREMENT,
    production_id INT NOT NULL,
    menu_id INT NULL,
    waste_stage VARCHAR(15) NOT NULL,
    reason VARCHAR(20) NOT NULL,
    waste_kg DECIMAL(8, 2) NOT NULL,
    recorded_by VARCHAR(100),
    recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_waste_prod FOREIGN KEY (production_id) REFERENCES meal_production(production_id) ON DELETE CASCADE,
    CONSTRAINT fk_waste_menu FOREIGN KEY (menu_id) REFERENCES weekly_menus(menu_id) ON DELETE SET NULL,
    CONSTRAINT chk_waste_stage CHECK (waste_stage IN ('PREPARATION', 'LEFTOVER', 'PLATE')),
    CONSTRAINT chk_waste_reason CHECK (reason IN ('OVERPRODUCTION', 'LOW_ATTENDANCE', 'POOR_QUALITY', 'SPOILAGE', 'OVERPORTIONING', 'OTHER')),
    CONSTRAINT chk_waste_kg CHECK (waste_kg >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_production_date ON meal_production(production_date, mess_id);
CREATE INDEX idx_waste_reason ON food_waste_log(reason);
CREATE INDEX idx_waste_menu ON food_waste_log(menu_id);

-- A4. Feedback becomes dish-level and carries a plate-leftover signal.
ALTER TABLE mess_feedbacks
    ADD COLUMN menu_id INT NULL AFTER slot_id,
    ADD COLUMN plate_left VARCHAR(10) NULL AFTER rating,
    ADD CONSTRAINT fk_fb_menu FOREIGN KEY (menu_id) REFERENCES weekly_menus(menu_id) ON DELETE SET NULL,
    ADD CONSTRAINT chk_fb_plate CHECK (plate_left IS NULL OR plate_left IN ('NONE', 'QUARTER', 'HALF', 'MOST'));

ALTER TABLE mess_feedbacks DROP CHECK chk_fb_category;
ALTER TABLE mess_feedbacks
    ADD CONSTRAINT chk_fb_category CHECK (category IN
        ('FOOD_QUALITY', 'HYGIENE', 'PORTION_SIZE', 'STAFF_BEHAVIOR', 'PUNCTUALITY', 'TASTE', 'FOOD_WASTE', 'OTHER'));

-- A5. Waste summary view: waste % and cost are DERIVED, never stored (keeps 3NF).
CREATE VIEW v_waste_summary AS
SELECT
    p.production_id,
    m.mess_name,
    p.production_date,
    ms.slot_name,
    p.diet_category,
    p.planned_headcount,
    p.prepared_kg,
    COALESCE(SUM(w.waste_kg), 0) AS waste_kg,
    ROUND(COALESCE(SUM(w.waste_kg), 0) / p.prepared_kg * 100, 1) AS waste_pct,
    ROUND(COALESCE(SUM(w.waste_kg), 0) * p.cost_per_kg, 2) AS waste_cost_inr
FROM meal_production p
JOIN messes m ON p.mess_id = m.mess_id
JOIN meal_slots ms ON p.slot_id = ms.slot_id
LEFT JOIN food_waste_log w ON w.production_id = p.production_id
GROUP BY p.production_id, m.mess_name, p.production_date, ms.slot_name,
         p.diet_category, p.planned_headcount, p.prepared_kg, p.cost_per_kg;

-- ---------------------------------------------------------------------------
-- B. SEED DATA (small pilot scale, matching the 10 seeded students)
-- menu_id 4 = Mess 1 Monday lunch NON_VEG, 8 = Mess 1 Monday dinner NON_VEG
-- ---------------------------------------------------------------------------
INSERT INTO meal_production (production_id, mess_id, slot_id, production_date, diet_category, planned_headcount, prepared_kg, cost_per_kg, prepared_by) VALUES
(1, 1, 2, CURDATE() - INTERVAL 1 DAY, 'NON_VEG', 4, 2.40, 240.00, 'Chef Raju'),
(2, 1, 4, CURDATE() - INTERVAL 1 DAY, 'NON_VEG', 4, 2.20, 240.00, 'Chef Raju'),
(3, 1, 2, CURDATE() - INTERVAL 2 DAY, 'NON_VEG', 4, 2.80, 240.00, 'Chef Raju'),
(4, 2, 2, CURDATE() - INTERVAL 1 DAY, 'VEG', 3, 1.80, 120.00, 'Chef Lakshmi'),
(5, 2, 2, CURDATE() - INTERVAL 2 DAY, 'VEG', 3, 1.60, 120.00, 'Chef Lakshmi');

INSERT INTO food_waste_log (production_id, menu_id, waste_stage, reason, waste_kg, recorded_by) VALUES
(1, 4, 'LEFTOVER', 'OVERPRODUCTION', 0.60, 'Supervisor Anil'),
(1, 4, 'PLATE', 'POOR_QUALITY', 0.30, 'Supervisor Anil'),
(2, 8, 'LEFTOVER', 'OVERPRODUCTION', 0.40, 'Supervisor Anil'),
(3, 4, 'LEFTOVER', 'OVERPRODUCTION', 0.90, 'Supervisor Anil'),
(3, 4, 'PLATE', 'POOR_QUALITY', 0.35, 'Supervisor Anil'),
(4, NULL, 'LEFTOVER', 'LOW_ATTENDANCE', 0.25, 'Supervisor Sita'),
(5, NULL, 'LEFTOVER', 'OVERPRODUCTION', 0.20, 'Supervisor Sita'),
(5, NULL, 'PLATE', 'OVERPORTIONING', 0.10, 'Supervisor Sita');

-- Tomorrow's lunch opt-outs (students 1 and 6 are in Mess 1)
INSERT INTO meal_optouts (student_id, mess_id, slot_id, meal_date, reason) VALUES
(1, 1, 2, CURDATE() + INTERVAL 1 DAY, 'ACADEMIC'),
(6, 1, 2, CURDATE() + INTERVAL 1 DAY, 'EATING_OUT');

-- Dish-level feedback with plate leftover
INSERT INTO mess_feedbacks (feedback_id, student_id, mess_id, slot_id, menu_id, rating, plate_left, category, comments, status) VALUES
(6, 1, 1, 2, 4, 2, 'HALF', 'TASTE', 'Chicken curry was too salty, left half of it.', 'OPEN'),
(7, 6, 1, 2, 4, 2, 'MOST', 'TASTE', 'Chicken was dry; could not finish it.', 'OPEN');

-- ---------------------------------------------------------------------------
-- C. QUERIES (numbered to continue queries.sql; add MIN_ROWS 13-18 in test_queries.py)
-- ---------------------------------------------------------------------------
SET @on_date = CURDATE();

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

-- QUERY 16: Production target for tomorrow's lunch
-- headcount = active subscribers - approved leaves - declared opt-outs
-- kg per head = (cooked - wasted) / planned heads over the last 14 days (actual consumption)
SET @target_date = CURDATE() + INTERVAL 1 DAY, @target_slot = 2;
WITH waste AS (
    SELECT production_id, SUM(waste_kg) AS waste_kg FROM food_waste_log GROUP BY production_id
),
hist AS (
    SELECT p.mess_id, p.slot_id, p.diet_category,
           SUM(p.prepared_kg - COALESCE(w.waste_kg, 0)) / SUM(p.planned_headcount) AS net_kg_per_head
    FROM meal_production p
    LEFT JOIN waste w ON w.production_id = p.production_id
    WHERE p.production_date >= CURDATE() - INTERVAL 14 DAY AND p.planned_headcount > 0
    GROUP BY p.mess_id, p.slot_id, p.diet_category
),
demand AS (
    SELECT sub.mess_id,
           CASE WHEN s.dietary_preference IN ('NON_VEG', 'EGG_ONLY') THEN 'NON_VEG' ELSE 'VEG' END AS diet_group,
           COUNT(*) AS headcount
    FROM student_mess_subscriptions sub
    JOIN students s ON sub.student_id = s.student_id
    WHERE sub.status = 'ACTIVE'
      AND s.account_status = 'ACTIVE'
      AND @target_date BETWEEN sub.start_date AND sub.end_date
      AND s.student_id NOT IN (SELECT student_id FROM mess_rebates
                               WHERE status = 'APPROVED' AND @target_date BETWEEN start_date AND end_date)
      AND s.student_id NOT IN (SELECT student_id FROM meal_optouts
                               WHERE meal_date = @target_date AND slot_id = @target_slot)
    GROUP BY sub.mess_id, diet_group
)
SELECT m.mess_name, d.diet_group, d.headcount,
       ROUND(h.net_kg_per_head, 3) AS net_kg_per_head,
       ROUND(d.headcount * h.net_kg_per_head, 2) AS suggested_kg_to_cook
FROM demand d
JOIN messes m ON d.mess_id = m.mess_id
LEFT JOIN hist h ON h.mess_id = d.mess_id AND h.diet_category = d.diet_group AND h.slot_id = @target_slot
ORDER BY m.mess_name, d.diet_group;

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