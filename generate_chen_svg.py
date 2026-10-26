"""
Script to generate a pixel-perfect, high-resolution Chen ER Diagram in SVG
strictly following classical database notation:
- Entity Set: Rectangle
- Weak Entity Set: Double Rectangle
- Relationship: Diamond
- Identifying Relationship: Double Diamond
- Primary Key Attribute: Oval with Solid Underline
- Partial Key / Discriminator: Oval with Dashed Underline
- Derived Attribute: Dashed Oval
- Multivalued Attribute: Double Oval
- Composite Attribute: Hierarchy of Ovals
- Total Participation: Double Line
- Partial Participation: Single Line
- Cardinalities: (1, N, M)
"""

import os

SVG_OUTPUT = os.path.join(os.path.dirname(__file__), "chen_er_diagram.svg")

def create_svg():
    width = 1750
    height = 1250

    svg = []
    svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="100%" height="100%">')
    svg.append('''<defs>
    <style>
        .title { font-family: 'Segoe UI', Arial, sans-serif; font-size: 24px; font-weight: bold; fill: #f8fafc; }
        .subtitle { font-family: 'Segoe UI', Arial, sans-serif; font-size: 14px; fill: #94a3b8; }
        .entity-text { font-family: 'Segoe UI', Arial, sans-serif; font-size: 15px; font-weight: bold; fill: #ffffff; text-anchor: middle; dominant-baseline: central; }
        .rel-text { font-family: 'Segoe UI', Arial, sans-serif; font-size: 13px; font-weight: bold; fill: #ffffff; text-anchor: middle; dominant-baseline: central; }
        .attr-text { font-family: 'Segoe UI', Arial, sans-serif; font-size: 11.5px; fill: #ffffff; text-anchor: middle; dominant-baseline: central; }
        .card-text { font-family: 'Segoe UI', Arial, sans-serif; font-size: 14px; font-weight: bold; fill: #38bdf8; }
        .legend-title { font-family: 'Segoe UI', Arial, sans-serif; font-size: 13px; font-weight: bold; fill: #fbbf24; }
        .legend-text { font-family: 'Segoe UI', Arial, sans-serif; font-size: 11px; fill: #cbd5e1; dominant-baseline: central; }
        .pk-line { stroke: #fbbf24; stroke-width: 1.5; }
        .partial-pk-line { stroke: #f43f5e; stroke-width: 1.5; stroke-dasharray: 4,3; }
        .conn-line { stroke: #64748b; stroke-width: 1.5; fill: none; }
        .total-conn { stroke: #38bdf8; stroke-width: 3.5; fill: none; }
    </style>
    <!-- Gradients & Filters -->
    <filter id="shadow" x="-5%" y="-5%" width="115%" height="115%">
        <feDropShadow dx="2" dy="3" stdDeviation="3" flood-color="#000" flood-opacity="0.45"/>
    </filter>
    <linearGradient id="bgGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="#090d16"/>
        <stop offset="100%" stop-color="#0f172a"/>
    </linearGradient>
    <linearGradient id="entityGrad" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#1e3a8a"/>
        <stop offset="100%" stop-color="#1d4ed8"/>
    </linearGradient>
    <linearGradient id="weakEntityGrad" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#4c1d95"/>
        <stop offset="100%" stop-color="#6d28d9"/>
    </linearGradient>
    <linearGradient id="relGrad" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#0f766e"/>
        <stop offset="100%" stop-color="#0d9488"/>
    </linearGradient>
    <linearGradient id="idRelGrad" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#9f1239"/>
        <stop offset="100%" stop-color="#be123c"/>
    </linearGradient>
    <linearGradient id="attrGrad" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#1e293b"/>
        <stop offset="100%" stop-color="#334155"/>
    </linearGradient>
    <linearGradient id="reqAttrGrad" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#854d0e"/>
        <stop offset="100%" stop-color="#b45309"/>
    </linearGradient>
</defs>''')

    # Background
    svg.append(f'<rect width="{width}" height="{height}" fill="url(#bgGrad)"/>')

    # Header Box
    svg.append('''
    <g transform="translate(40, 30)">
        <text class="title" x="0" y="24">MESS MANAGEMENT SYSTEM — COMPLETE CHEN'S ER DIAGRAM</text>
        <text class="subtitle" x="0" y="48">Classical ER Model with Strong &amp; Weak Entities, Identifying Relationships, Composite, Multivalued, &amp; Derived Attributes</text>
    </g>''')

    # Legend Panel
    legend_x = 1360
    legend_y = 35
    svg.append(f'''
    <g transform="translate({legend_x}, {legend_y})">
        <rect width="350" height="235" rx="8" fill="#1e293b" stroke="#334155" stroke-width="1.5" filter="url(#shadow)"/>
        <text class="legend-title" x="18" y="24">ER NOTATION REFERENCE (CHEN)</text>
        
        <!-- Strong Entity -->
        <rect x="20" y="40" width="50" height="22" rx="3" fill="#1d4ed8" stroke="#60a5fa" stroke-width="1.5"/>
        <text class="legend-text" x="80" y="52">Strong Entity Set (Rectangle)</text>
        
        <!-- Weak Entity -->
        <rect x="18" y="70" width="54" height="24" rx="3" fill="none" stroke="#a78bfa" stroke-width="1.5"/>
        <rect x="22" y="74" width="46" height="16" rx="2" fill="#6d28d9" stroke="#a78bfa" stroke-width="1.5"/>
        <text class="legend-text" x="80" y="82">Weak Entity Set (Double Rect)</text>

        <!-- Relationship -->
        <polygon points="45,102 65,113 45,124 25,113" fill="#0d9488" stroke="#2dd4bf" stroke-width="1.5"/>
        <text class="legend-text" x="80" y="113">Relationship Set (Diamond)</text>

        <!-- Identifying Relationship -->
        <polygon points="45,132 67,144 45,156 23,144" fill="none" stroke="#f43f5e" stroke-width="1.2"/>
        <polygon points="45,136 62,144 45,152 28,144" fill="#be123c" stroke="#f43f5e" stroke-width="1.2"/>
        <text class="legend-text" x="80" y="144">Identifying Rel (Double Diamond)</text>

        <!-- Attributes -->
        <ellipse cx="33" cy="172" rx="14" ry="8" fill="#334155" stroke="#fbbf24" stroke-width="1.2"/>
        <line x1="24" y1="176" x2="42" y2="176" stroke="#fbbf24" stroke-width="1.2"/>
        <text class="legend-text" x="80" y="172">Primary Key (Underlined)</text>

        <ellipse cx="33" cy="194" rx="14" ry="8" fill="#334155" stroke="#a78bfa" stroke-width="1.2"/>
        <ellipse cx="33" cy="194" rx="11" ry="5.5" fill="none" stroke="#a78bfa" stroke-width="1"/>
        <text class="legend-text" x="80" y="194">Multivalued (Double Oval)</text>

        <ellipse cx="33" cy="216" rx="14" ry="8" fill="#334155" stroke="#38bdf8" stroke-width="1.2" stroke-dasharray="3,2"/>
        <text class="legend-text" x="80" y="216">Derived Attribute (Dashed Oval)</text>
    </g>''')

    # Structural Connection Lines
    connections = [
        # STUDENT Attributes
        ("620,440", "470,330"), # Reg No (PK)
        ("620,440", "450,400"), # Name (Composite)
        ("450,400", "320,375"), # -> First_Name
        ("450,400", "320,415"), # -> Last_Name
        ("620,440", "460,470"), # Room_No
        ("620,440", "500,530"), # Veg_Non_Veg
        ("620,440", "580,560"), # Phone_Number (Multivalued)
        ("620,440", "670,565"), # Email
        ("620,440", "750,555"), # Department
        ("620,440", "820,520"), # Year_of_Study
        ("620,440", "840,460"), # DOB
        ("840,460", "960,460"), # -> Age (Derived)

        # HOSTEL Attributes
        ("240,190", "110,130"), # Hostel_ID (PK)
        ("240,190", "100,190"), # Hostel_Name
        ("240,190", "110,245"), # Block_Code
        ("240,190", "220,110"), # Gender_Type
        ("240,190", "330,120"), # Warden_Name

        # MESS Attributes
        ("1050,190", "1000,105"), # Mess_ID (PK)
        ("1050,190", "1120,105"), # Mess_Name
        ("1050,190", "1220,140"), # Mess_Type
        ("1050,190", "1230,200"), # Capacity
        ("1050,190", "1220,255"), # Monthly_Base_Fee
        ("1050,190", "1110,270"), # Rebate_Rate_Per_Day

        # MEAL_SLOT Attributes
        ("1100,750", "1190,670"), # Slot_ID (PK)
        ("1100,750", "1240,730"), # Slot_Name
        ("1100,750", "1230,795"), # Timings
        ("1100,750", "1180,850"), # Guest_Rate

        # WEAK ENTITY: MESS_REBATE Attributes
        ("310,800", "180,750"), # Rebate_No (Partial Key)
        ("310,800", "160,805"), # Start_Date
        ("310,800", "175,860"), # End_Date
        ("310,800", "220,910"), # Reason
        ("310,800", "310,920"), # Status
        ("310,800", "410,910"), # Leave_Days (Derived)

        # WEAK ENTITY: MONTHLY_BILL Attributes
        ("670,820", "550,910"), # Billing_Month (Partial Key)
        ("670,820", "640,940"), # Base_Fee
        ("670,820", "740,940"), # Rebate_Discount (Derived)
        ("670,820", "830,910"), # Net_Payable (Derived)
        ("670,820", "840,845"), # Payment_Status

        # Relationships
        ("240,190", "390,280"), # HOSTEL to RESIDES_IN
        ("390,280", "620,440"), # RESIDES_IN to STUDENT
        ("240,190", "600,190"), # HOSTEL to HOUSES_MESS
        ("600,190", "1050,190"), # HOUSES_MESS to MESS
        ("620,440", "850,290"), # STUDENT to SUBSCRIBES
        ("850,290", "1050,190"), # SUBSCRIBES to MESS
        ("850,290", "960,340"), # SUBSCRIBES Attr: Plan_Type
        ("850,290", "870,370"), # SUBSCRIBES Attr: Start_Date

        # Identifying Rel: STUDENT to MESS_REBATE
        ("620,440", "440,640"), # STUDENT to APPLIES_REBATE
        ("440,640", "310,800"), # APPLIES_REBATE to MESS_REBATE

        # Identifying Rel: STUDENT to MONTHLY_BILL
        ("620,440", "650,650"), # STUDENT to GENERATES_BILL
        ("650,650", "670,820"), # GENERATES_BILL to MONTHLY_BILL
        ("1050,190", "860,570"), # MESS to GENERATES_BILL
        ("860,570", "650,650"),

        # MEAL_ATTENDANCE
        ("620,440", "870,610"), # STUDENT to CONSUMES
        ("1050,190", "870,610"), # MESS to CONSUMES
        ("1100,750", "870,610"), # MEAL_SLOT to CONSUMES
        ("870,610", "980,590"), # CONSUMES Attr: Swipe_Timestamp
        ("870,610", "990,635"), # CONSUMES Attr: Diet_Served (Veg/NonVeg)
    ]

    for p1, p2 in connections:
        x1, y1 = p1.split(",")
        x2, y2 = p2.split(",")
        svg.append(f'<line class="conn-line" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/>')

    # Total Participation Double lines:
    # 1. STUDENT participation in RESIDES_IN (every student must live in a hostel)
    svg.append('<line class="total-conn" x1="620" y1="440" x2="390" y2="280"/>')
    # 2. MESS_REBATE in APPLIES_REBATE (weak entity has total participation)
    svg.append('<line class="total-conn" x1="310" y1="800" x2="440" y2="640"/>')
    # 3. MONTHLY_BILL in GENERATES_BILL (weak entity has total participation)
    svg.append('<line class="total-conn" x1="670" y1="820" x2="650" y2="650"/>')

    # -------------------------------------------------------------
    # ENTITIES
    # -------------------------------------------------------------
    # Strong Entities
    def draw_entity(x, y, w, h, name):
        rx = x - w/2
        ry = y - h/2
        return f'''
        <g transform="translate({rx}, {ry})" filter="url(#shadow)">
            <rect width="{w}" height="{h}" rx="5" fill="url(#entityGrad)" stroke="#60a5fa" stroke-width="2"/>
            <text class="entity-text" x="{w/2}" y="{h/2}">{name}</text>
        </g>'''

    # Weak Entities
    def draw_weak_entity(x, y, w, h, name):
        rx = x - w/2
        ry = y - h/2
        return f'''
        <g transform="translate({rx}, {ry})" filter="url(#shadow)">
            <rect width="{w}" height="{h}" rx="5" fill="none" stroke="#c084fc" stroke-width="2"/>
            <rect x="5" y="5" width="{w-10}" height="{h-10}" rx="3" fill="url(#weakEntityGrad)" stroke="#c084fc" stroke-width="1.8"/>
            <text class="entity-text" x="{w/2}" y="{h/2}">{name}</text>
        </g>'''

    # Relationships (Diamond)
    def draw_relationship(cx, cy, rw, rh, name):
        pts = f"{cx},{cy-rh} {cx+rw},{cy} {cx},{cy+rh} {cx-rw},{cy}"
        return f'''
        <g filter="url(#shadow)">
            <polygon points="{pts}" fill="url(#relGrad)" stroke="#2dd4bf" stroke-width="2"/>
            <text class="rel-text" x="{cx}" y="{cy}">{name}</text>
        </g>'''

    # Identifying Relationships (Double Diamond)
    def draw_id_relationship(cx, cy, rw, rh, name):
        pts_out = f"{cx},{cy-rh} {cx+rw},{cy} {cx},{cy+rh} {cx-rw},{cy}"
        pts_in = f"{cx},{cy-rh+6} {cx+rw-7},{cy} {cx},{cy+rh-6} {cx-rw+7},{cy}"
        return f'''
        <g filter="url(#shadow)">
            <polygon points="{pts_out}" fill="none" stroke="#fb7185" stroke-width="1.8"/>
            <polygon points="{pts_in}" fill="url(#idRelGrad)" stroke="#fb7185" stroke-width="1.8"/>
            <text class="rel-text" x="{cx}" y="{cy}">{name}</text>
        </g>'''

    # Attributes
    def draw_attribute(cx, cy, rx, ry, name, attr_type="normal", is_required=False):
        grad = "url(#reqAttrGrad)" if is_required else "url(#attrGrad)"
        border = "#f59e0b" if is_required else "#64748b"
        
        if attr_type == "pk":
            border = "#fbbf24"
            text_len = len(name) * 6.5
            return f'''
            <g filter="url(#shadow)">
                <ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{grad}" stroke="{border}" stroke-width="2"/>
                <text class="attr-text" x="{cx}" y="{cy}">{name}</text>
                <line class="pk-line" x1="{cx - text_len/2}" y1="{cy+7}" x2="{cx + text_len/2}" y2="{cy+7}"/>
            </g>'''
        elif attr_type == "partial_pk":
            border = "#f43f5e"
            text_len = len(name) * 6.5
            return f'''
            <g filter="url(#shadow)">
                <ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{grad}" stroke="{border}" stroke-width="1.8"/>
                <text class="attr-text" x="{cx}" y="{cy}">{name}</text>
                <line class="partial-pk-line" x1="{cx - text_len/2}" y1="{cy+7}" x2="{cx + text_len/2}" y2="{cy+7}"/>
            </g>'''
        elif attr_type == "multivalued":
            border = "#a78bfa"
            return f'''
            <g filter="url(#shadow)">
                <ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{grad}" stroke="{border}" stroke-width="1.8"/>
                <ellipse cx="{cx}" cy="{cy}" rx="{rx-4}" ry="{ry-3}" fill="none" stroke="{border}" stroke-width="1.2"/>
                <text class="attr-text" x="{cx}" y="{cy}">{name}</text>
            </g>'''
        elif attr_type == "derived":
            border = "#38bdf8"
            return f'''
            <g filter="url(#shadow)">
                <ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{grad}" stroke="{border}" stroke-width="1.8" stroke-dasharray="4,3"/>
                <text class="attr-text" x="{cx}" y="{cy}">{name}</text>
            </g>'''
        else: # normal
            return f'''
            <g filter="url(#shadow)">
                <ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{grad}" stroke="{border}" stroke-width="1.4"/>
                <text class="attr-text" x="{cx}" y="{cy}">{name}</text>
            </g>'''

    # Place Entities
    svg.append(draw_entity(240, 190, 150, 48, "HOSTEL"))
    svg.append(draw_entity(1050, 190, 150, 48, "MESS"))
    svg.append(draw_entity(620, 440, 160, 52, "STUDENT"))
    svg.append(draw_entity(1100, 750, 150, 48, "MEAL_SLOT"))

    # Weak Entities
    svg.append(draw_weak_entity(310, 800, 160, 52, "MESS_REBATE"))
    svg.append(draw_weak_entity(670, 820, 160, 52, "MONTHLY_BILL"))

    # Relationships
    svg.append(draw_relationship(390, 280, 68, 38, "RESIDES_IN"))
    svg.append(draw_relationship(600, 190, 75, 38, "HOUSES_MESS"))
    svg.append(draw_relationship(850, 290, 70, 38, "SUBSCRIBES"))
    svg.append(draw_relationship(870, 610, 80, 40, "CONSUMES"))

    # Identifying Relationships
    svg.append(draw_id_relationship(440, 640, 80, 42, "APPLIES_FOR"))
    svg.append(draw_id_relationship(650, 650, 84, 42, "GENERATED_FOR"))

    # Cardinality Labels
    svg.append('<text class="card-text" x="295" y="240">1</text>')
    svg.append('<text class="card-text" x="510" y="380">N</text>')
    svg.append('<text class="card-text" x="350" y="180">1</text>')
    svg.append('<text class="card-text" x="930" y="180">N</text>')
    svg.append('<text class="card-text" x="730" y="370">M</text>')
    svg.append('<text class="card-text" x="940" y="240">N</text>')
    svg.append('<text class="card-text" x="540" y="550">1</text>')
    svg.append('<text class="card-text" x="370" y="730">N</text>')
    svg.append('<text class="card-text" x="625" y="540">1</text>')
    svg.append('<text class="card-text" x="655" y="750">N</text>')
    svg.append('<text class="card-text" x="770" y="520">N</text>')
    svg.append('<text class="card-text" x="970" y="440">M</text>')
    svg.append('<text class="card-text" x="1000" y="700">P</text>')

    # -------------------------------------------------------------
    # ATTRIBUTES
    # -------------------------------------------------------------
    # STUDENT Attributes (Explicitly requested highlighted!)
    svg.append(draw_attribute(470, 330, 78, 22, "Registration_No", "pk", is_required=True))
    svg.append(draw_attribute(450, 400, 52, 20, "Name", "normal", is_required=True))
    svg.append(draw_attribute(320, 375, 46, 17, "First_Name", "normal"))
    svg.append(draw_attribute(320, 415, 46, 17, "Last_Name", "normal"))
    svg.append(draw_attribute(460, 470, 56, 20, "Room_No", "normal", is_required=True))
    svg.append(draw_attribute(500, 530, 68, 20, "Veg_Non_Veg", "normal", is_required=True))
    svg.append(draw_attribute(580, 560, 66, 20, "Phone_Number", "multivalued"))
    svg.append(draw_attribute(670, 565, 52, 19, "Email", "normal"))
    svg.append(draw_attribute(750, 555, 56, 19, "Department", "normal"))
    svg.append(draw_attribute(820, 520, 58, 19, "Year_of_Study", "normal"))
    svg.append(draw_attribute(840, 460, 45, 18, "DOB", "normal"))
    svg.append(draw_attribute(960, 460, 46, 18, "Age", "derived"))

    # HOSTEL Attributes
    svg.append(draw_attribute(110, 130, 54, 18, "Hostel_ID", "pk"))
    svg.append(draw_attribute(100, 190, 56, 18, "Hostel_Name", "normal"))
    svg.append(draw_attribute(110, 245, 54, 18, "Block_Code", "normal"))
    svg.append(draw_attribute(220, 110, 56, 18, "Gender_Type", "normal"))
    svg.append(draw_attribute(330, 120, 60, 18, "Warden_Name", "normal"))

    # MESS Attributes
    svg.append(draw_attribute(1000, 105, 50, 18, "Mess_ID", "pk"))
    svg.append(draw_attribute(1120, 105, 55, 18, "Mess_Name", "normal"))
    svg.append(draw_attribute(1220, 140, 52, 18, "Mess_Type", "normal"))
    svg.append(draw_attribute(1230, 200, 48, 18, "Capacity", "normal"))
    svg.append(draw_attribute(1220, 255, 68, 18, "Monthly_Base_Fee", "normal"))
    svg.append(draw_attribute(1110, 270, 72, 18, "Rebate_Rate_Per_Day", "normal"))

    # MEAL_SLOT Attributes
    svg.append(draw_attribute(1190, 670, 46, 18, "Slot_ID", "pk"))
    svg.append(draw_attribute(1240, 730, 52, 18, "Slot_Name", "normal"))
    svg.append(draw_attribute(1230, 795, 48, 18, "Timings", "normal"))
    svg.append(draw_attribute(1180, 850, 52, 18, "Guest_Rate", "normal"))

    # SUBSCRIBES Relationship Attributes
    svg.append(draw_attribute(960, 340, 48, 17, "Plan_Type", "normal"))
    svg.append(draw_attribute(870, 370, 50, 17, "Start_Date", "normal"))

    # CONSUMES Relationship Attributes
    svg.append(draw_attribute(980, 590, 65, 18, "Swipe_Timestamp", "normal"))
    svg.append(draw_attribute(990, 635, 55, 18, "Diet_Served", "normal"))

    # WEAK ENTITY: MESS_REBATE Attributes
    svg.append(draw_attribute(180, 750, 58, 18, "Rebate_No", "partial_pk"))
    svg.append(draw_attribute(160, 805, 52, 18, "Start_Date", "normal"))
    svg.append(draw_attribute(175, 860, 50, 18, "End_Date", "normal"))
    svg.append(draw_attribute(220, 910, 46, 18, "Reason", "normal"))
    svg.append(draw_attribute(310, 920, 46, 18, "Status", "normal"))
    svg.append(draw_attribute(410, 910, 58, 18, "Leave_Days", "derived"))

    # WEAK ENTITY: MONTHLY_BILL Attributes
    svg.append(draw_attribute(550, 910, 65, 18, "Billing_Month", "partial_pk"))
    svg.append(draw_attribute(640, 940, 50, 18, "Base_Fee", "normal"))
    svg.append(draw_attribute(740, 940, 68, 18, "Rebate_Discount", "derived"))
    svg.append(draw_attribute(830, 910, 60, 18, "Net_Payable", "derived"))
    svg.append(draw_attribute(840, 845, 65, 18, "Payment_Status", "normal"))

    svg.append('</svg>')

    content = "\n".join(svg)
    with open(SVG_OUTPUT, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"[OK] Generated Chen ER Diagram SVG: {SVG_OUTPUT}")

if __name__ == "__main__":
    create_svg()
