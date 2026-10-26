# Classical Chen's Entity-Relationship (ER) Model

This document outlines the complete **Chen's ER Model** for the **Mess Management System**, adhering to standard database textbook notation (Rectangles, Diamonds, Double Shapes, Ovals, Underlines, and Dashed lines).

---

## 1. Classical ER Diagram Notation Reference

| Symbol | Representation | Meaning in ER Model | Application in this System |
| :--- | :--- | :--- | :--- |
| **Rectangle** | `[ Entity ]` | **Strong Entity Set** | `STUDENT`, `HOSTEL`, `MESS`, `MEAL_SLOT` |
| **Double Rectangle** | `[[ Weak Entity ]]` | **Weak Entity Set** (Existence dependent on owner) | `MESS_REBATE`, `MONTHLY_BILL` |
| **Diamond** | `< Relationship >` | **Relationship Set** | `RESIDES_IN`, `HOUSES_MESS`, `SUBSCRIBES`, `CONSUMES` |
| **Double Diamond** | `<< Identifying Rel >>` | **Identifying Relationship** (Connects weak entity to owner) | `APPLIES_FOR` (Rebate), `GENERATED_FOR` (Bill) |
| **Oval with Solid Underline** | `( Key_Attr )` | **Primary Key** | `Registration_No`, `Hostel_ID`, `Mess_ID`, `Slot_ID` |
| **Oval with Dashed Underline** | `( -Partial_Key- )` | **Partial Key / Discriminator** (For weak entities) | `Rebate_No` (in Rebate), `Billing_Month` (in Bill) |
| **Double Oval** | `(( Multivalued ))` | **Multivalued Attribute** (Can have multiple values) | `Phone_Number` (Students can have multiple contact numbers) |
| **Dashed Oval** | `(- Derived -)` | **Derived Attribute** (Computed dynamically from other attributes) | `Age` (from DOB), `Leave_Days` (from dates), `Net_Payable` |
| **Branching Ovals** | `(Comp) -> (A1), (A2)` | **Composite Attribute** (Composed of sub-parts) | `Name` $\rightarrow$ `First_Name`, `Last_Name` |
| **Double Line** | `═══════` | **Total Participation** (Every entity must participate) | Every `STUDENT` must reside in a `HOSTEL`; every `REBATE` must have a `STUDENT` |
| **Single Line** | `───────` | **Partial Participation** | Not every student has applied for a rebate |

---

## 2. Textual / Structural Diagram

```text
                               +-----------------------------+
                               |           HOSTEL            |
                               +-----------------------------+
                               /     |       |       \       \
                       (Hostel_ID) (Name) (Block) (Gender) (Warden)
                          [PK]
                             \
                              \ (1)
                               \
                        < RESIDES_IN >
                               /
                         (N)  //  [Total Participation]
                             //
               +-------------------------------------------------+
               |                    STUDENT                      |
               +-------------------------------------------------+
               /       |        |        |        \        \      \
       (Reg_No)      (Name)  (Room_No) (Veg/   ((Phone)) (Email)  (DOB)
         [PK]        /    \    [Req]   NonVeg)  [Multi]             \
               (First)    (Last)        [Req]                     (-Age-)
                                                                  [Derived]
                 // (1)                               \\ (1)
                //                                     \\
      << APPLIES_FOR >>                       << GENERATED_FOR >>
        [Identifying]                           [Identifying]
              // (N)                                  // (N)
             //                                      //
   +====================+                  +=====================+
   |    MESS_REBATE     |                  |    MONTHLY_BILL     |
   |   (Weak Entity)    |                  |    (Weak Entity)    |
   +====================+                  +=====================+
    /     |      \     \                    /      |        \     \
(Rebate_No) (Dates) (Reason) (-Days-)   (Month) (Base_Fee) (-Rebate-) (-Net_Payable-)
 [Partial]                   [Derived]  [Partial]          [Derived]   [Derived]
```

---

## 3. Detailed Entity & Attribute Catalog

### A. Strong Entity: `STUDENT`
*Entity possessing its own primary key.*
- **`Registration_No`** $\rightarrow$ **Primary Key** (Solid Underline). Unique institutional identifier.
- **`Name`** $\rightarrow$ **Composite Attribute** branching into:
  - `First_Name`
  - `Last_Name`
- **`Room_No`** $\rightarrow$ Simple Attribute (Room allocation).
- **`Veg_Non_Veg`** $\rightarrow$ Simple Attribute with domain check (`VEG`, `NON_VEG`, `JAIN`, `EGG_ONLY`).
- **`Phone_Number`** $\rightarrow$ **Multivalued Attribute** (Double Oval): A student may register both personal and guardian contact numbers.
- **`DOB`** $\rightarrow$ Simple Attribute (Date of Birth).
- **`Age`** $\rightarrow$ **Derived Attribute** (Dashed Oval): Dynamically calculated as $\text{Current\_Date} - \text{DOB}$.
- **`Email`**, **`Department`**, **`Year_of_Study`** $\rightarrow$ Simple attributes.

### B. Weak Entity: `MESS_REBATE` (Mess Leaves)
*Cannot exist without an associated `STUDENT`.*
- **Owner Entity**: `STUDENT`
- **Identifying Relationship**: `APPLIES_FOR` (**Double Diamond**)
- **`Rebate_No`** $\rightarrow$ **Partial Key / Discriminator** (Dashed Underline): Numbered relative to the student (e.g. Leave #1, Leave #2).
- **`Start_Date`**, **`End_Date`** $\rightarrow$ Date bounds.
- **`Reason`**, **`Status`** $\rightarrow$ Text and ENUM (`PENDING`, `APPROVED`, `REJECTED`).
- **`Leave_Days`** $\rightarrow$ **Derived Attribute** (Dashed Oval): $\text{End\_Date} - \text{Start\_Date} + 1$.

### C. Weak Entity: `MONTHLY_BILL`
*Generated monthly per student; existence dependent on `STUDENT` and `MESS`.*
- **Owner Entities**: `STUDENT` & `MESS`
- **Identifying Relationship**: `GENERATED_FOR` (**Double Diamond**)
- **`Billing_Month`** $\rightarrow$ **Partial Key / Discriminator** (Dashed Underline): Month and year cycle.
- **`Base_Fee`** $\rightarrow$ Regular monthly mess rate.
- **`Rebate_Discount`** $\rightarrow$ **Derived Attribute** (Dashed Oval): $\text{Leave\_Days} \times \text{Daily\_Rebate\_Rate}$.
- **`Net_Payable`** $\rightarrow$ **Derived Attribute** (Dashed Oval): $\text{Base\_Fee} - \text{Rebate\_Discount} + \text{Guest\_Charges}$.
- **`Payment_Status`** $\rightarrow$ `PAID`, `UNPAID`, `OVERDUE`.

### D. Strong Entity: `HOSTEL`
- **`Hostel_ID`** $\rightarrow$ **Primary Key** (Solid Underline).
- `Hostel_Name`, `Block_Code`, `Gender_Type`, `Warden_Name`, `Warden_Contact`.

### E. Strong Entity: `MESS`
- **`Mess_ID`** $\rightarrow$ **Primary Key** (Solid Underline).
- `Mess_Name`, `Mess_Type` (`PURE_VEG`, `VEG_NON_VEG`), `Capacity`, `Caterer_Name`, `Monthly_Base_Fee`, `Rebate_Rate_Per_Day`.

### F. Strong Entity: `MEAL_SLOT`
- **`Slot_ID`** $\rightarrow$ **Primary Key** (Solid Underline).
- `Slot_Name` (`BREAKFAST`, `LUNCH`, `SNACKS`, `DINNER`), `Start_Time`, `End_Time`, `Guest_Rate`.

---

## 4. Relationship Sets & Cardinalities

1. **`RESIDES_IN`** (Relationship between `STUDENT` and `HOSTEL`):
   - **Cardinality**: $N : 1$ (Many students reside in one hostel).
   - **Participation**: **Total** for `STUDENT` (**Double Line** — Every student must be assigned a hostel).
2. **`SUBSCRIBES`** (Relationship between `STUDENT` and `MESS`):
   - **Cardinality**: $M : N$ (Students enroll in mess plans across terms).
   - **Relationship Attributes**: `Start_Date`, `End_Date`, `Plan_Type`.
3. **`CONSUMES`** (Ternary Relationship between `STUDENT`, `MESS`, `MEAL_SLOT`):
   - **Cardinality**: $M : N : P$.
   - **Relationship Attributes**: `Swipe_Timestamp`, `Diet_Served` (Veg / Non-Veg verification).
4. **`HOUSES_MESS`** (Relationship between `HOSTEL` and `MESS`):
   - **Cardinality**: $1 : N$.
5. **`APPLIES_FOR`** (**Identifying Relationship**):
   - Connects `STUDENT` (Owner) with `MESS_REBATE` (Weak Entity).
   - **Double Diamond** with Total Participation from `MESS_REBATE`.
6. **`GENERATED_FOR`** (**Identifying Relationship**):
   - Connects `STUDENT` / `MESS` with `MONTHLY_BILL` (Weak Entity).
   - **Double Diamond** with Total Participation from `MONTHLY_BILL`.

---

## 5. Direct Files Available in `d:\Prj`

- [`chen_er_diagram.svg`](file:///d:/Prj/chen_er_diagram.svg): Raw Scalable Vector Graphic with all classical shapes, colored outlines, double borders, and text labels.
- [`chen_er_diagram.html`](file:///d:/Prj/chen_er_diagram.html): Interactive viewer with pan and zoom controls.
- [`schema.sql`](file:///d:/Prj/schema.sql): Relational DDL implementation enforcing all foreign keys and constraints.
