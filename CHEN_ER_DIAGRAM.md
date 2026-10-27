# Classical Chen's Entity-Relationship (ER) Model

Chen-notation **core model** of the **Mess Management System**. Attribute names follow `schema.sql`.

> **Scope.** Diagram covers 4 strong entities + 2 weak entities. Other tables (`diet_map`, `weekly_menus`, `meal_optouts`, `meal_production`, `food_waste_log`, `guest_meals`, `mess_feedbacks`, `inventory_items`) appear only in the Mermaid ER in [`er_diagram.html`](er_diagram.html) / [`database_design.md`](database_design.md) (all 16 tables).

---

## 1. Notation Reference

| Symbol | Representation | Meaning | Used here |
| :--- | :--- | :--- | :--- |
| **Rectangle** | `[ Entity ]` | Strong entity | `STUDENT`, `HOSTEL`, `MESS`, `MEAL_SLOT` |
| **Double Rectangle** | `[[ Weak Entity ]]` | Weak entity | `MESS_REBATE`, `MONTHLY_BILL` |
| **Diamond** | `< Relationship >` | Relationship set | `RESIDES_IN`, `HOUSES_MESS`, `SUBSCRIBES`, `CONSUMES` |
| **Double Diamond** | `<< Identifying Rel >>` | Weak entity to owner | `APPLIES_FOR`, `GENERATED_FOR` |
| **Solid-underlined oval** | `( Key )` | Primary key | `Registration_No`, `Hostel_ID`, `Mess_ID`, `Slot_ID` |
| **Dashed-underlined oval** | `( -Partial- )` | Partial key / discriminator | `Rebate_No`, `Billing_Month` |
| **Dashed oval** | `(- Derived -)` | Derived attribute | `Leave_Days`, `Net_Payable` |
| **Double oval** | `(( Multi ))` | Multivalued | *not used* (`phone_number` is single-valued in schema) |
| **Branching ovals** | `(Comp) -> (A),(B)` | Composite | *not used* (`full_name` is single column) |
| **Double line** | `═══` | Total participation | `STUDENT`→`RESIDES_IN`, `MESS_REBATE`→`APPLIES_FOR`, `MONTHLY_BILL`→`GENERATED_FOR` |
| **Gold-filled oval** | | Required attribute | Registration_No, Full_Name, Room_No, Dietary_Preference |

---

## 2. Entity & Attribute Catalog

### A. Strong: `STUDENT` (table `students`)
- **`Registration_No`** → primary key (conceptual; physical PK is `student_id`, `registration_no` is `UNIQUE`).
- `Full_Name`, `Room_No`, `Dietary_Preference` (required; `VEG`, `NON_VEG`, `JAIN`, `EGG_ONLY`; FK to `diet_map` → kitchen group `VEG` / `NON_VEG`).
- `Email`, `Phone_Number`, `Emergency_Contact`, `Department`, `Year_of_Study`, `Account_Status` (`ACTIVE`, `INACTIVE`, `SUSPENDED`, `ALUMNI`).

### B. Weak: `MESS_REBATE` (table `mess_rebates`, mess leave)
- **Owner**: `STUDENT`. **Identifying relationship**: `APPLIES_FOR` (double diamond).
- **`Rebate_No`** → partial key (conceptual: leave #1, #2 per student). Physical table uses surrogate `rebate_id`; `ON DELETE CASCADE` from student keeps the existence dependency.
- `Start_Date`, `End_Date`, `Reason`, `Status` (`PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`).
- **`Leave_Days`** → derived: `End_Date − Start_Date + 1` (computed in Q3, not stored).

### C. Weak: `MONTHLY_BILL` (table `monthly_bills`)
- **Owner**: `STUDENT`; also references `MESS` (FK, part of unique key `student_id, mess_id, billing_month, billing_year`). Diagram draws only the STUDENT identifying link.
- **Identifying relationship**: `GENERATED_FOR` (double diamond).
- **`Billing_Month`** → partial key (with `Billing_Year`).
- `Base_Fee`, `Rebate_Amount`, `Guest_Charges`, `Payment_Status` (`UNPAID`, `PAID`, `OVERDUE`, `WAIVED`).
- **`Net_Payable`** → derived: `Base_Fee − Rebate_Amount + Guest_Charges + Fines_Or_Extras` (stored generated column).
- `Rebate_Amount` is a stored snapshot (`rebate_days` × mess `per_day_rebate_rate` at billing time), **not** derived.

### D. Strong: `HOSTEL` (table `hostels`)
- **`Hostel_ID`** PK. `Hostel_Name`, `Block_Code`, `Gender_Type` (`MALE`, `FEMALE`, `COED`), `Warden_Name`, `Warden_Contact`.

### E. Strong: `MESS` (table `messes`)
- **`Mess_ID`** PK. `Mess_Name`, `Mess_Type` (`PURE_VEG`, `VEG_NON_VEG`, `SPECIAL_DIET`), `Capacity`, `Caterer_Name`, `Monthly_Base_Fee`, `Rebate_Rate_Per_Day` (`per_day_rebate_rate`).

### F. Strong: `MEAL_SLOT` (table `meal_slots`)
- **`Slot_ID`** PK. `Slot_Name` (`BREAKFAST`, `LUNCH`, `SNACKS`, `DINNER`), `Timings` (`start_time`, `end_time`), `Guest_Rate`.

---

## 3. Relationship Sets & Cardinalities

1. **`RESIDES_IN`** (`STUDENT` – `HOSTEL`): N : 1, total for `STUDENT` (`students.hostel_id NOT NULL`).
2. **`HOUSES_MESS`** (`HOSTEL` – `MESS`): 1 : N, partial (`messes.hostel_id` nullable).
3. **`SUBSCRIBES`** (`STUDENT` – `MESS`): M : N over time, via `student_mess_subscriptions`. Attributes: `Status`, `Plan_Type` (`MONTHLY`, `SEMESTER`, `ANNUAL`), `Start_Date`, `End_Date`. Rule: at most **one ACTIVE** subscription per student (`uq_one_active_sub`).
4. **`CONSUMES`** (ternary `STUDENT` – `MESS` – `MEAL_SLOT`): M : N : P, via `meal_attendance` (unique per student + slot + date). Attributes: `Swipe_Timestamp` (`scanned_at`), `Diet_Served`.
5. **`APPLIES_FOR`** (identifying): `STUDENT` 1 : N `MESS_REBATE`, total on weak side.
6. **`GENERATED_FOR`** (identifying): `STUDENT` 1 : N `MONTHLY_BILL`, total on weak side.

---

## 4. Files

- [`generate_chen_svg.py`](generate_chen_svg.py): generator. Edit model in `build()`, run `python generate_chen_svg.py`.
- [`chen_er_diagram.svg`](chen_er_diagram.svg): generated diagram.
- [`chen_er_diagram.html`](chen_er_diagram.html): pan/zoom viewer (serve over HTTP: `python -m http.server`).
- [`er_diagram.html`](er_diagram.html): Mermaid ER, all 16 tables.
- [`schema.sql`](schema.sql): DDL, source of truth.
