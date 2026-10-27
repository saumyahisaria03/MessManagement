"""
Generates a Chen-notation ER diagram (SVG) for the Mess Management System.

Notation
- Entity: rectangle                    - Weak entity: double rectangle
- Relationship: diamond                - Identifying relationship: double diamond
- Primary key: underlined oval         - Partial key: dashed-underlined oval
- Multivalued: double oval             - Derived: dashed oval
- Composite: oval with child ovals     - Total participation: double line

Design notes
- One token table (TOKENS) drives every colour, so the palette is changed in one place.
- Colour encodes role, never decoration: blue = entity, violet = weak entity,
  teal = relationship, rose = identifying relationship, gold = key / required,
  cyan = derived. Everything else is neutral.
- Connectors are clipped to each shape's real outline (rectangle / diamond / ellipse),
  so lines never run through shapes or stop short of them.
- Structural lines (entity <-> relationship) are heavier than attribute lines,
  giving a clear three-level hierarchy: entities > relationships > attributes.
- Flat fills, no drop-shadows or gradients: shapes stay crisp when zoomed.
- Attribute clusters are arranged around their owner with even spacing and
  kept clear of relationship lines.
"""

import math
import os
from xml.sax.saxutils import escape

SVG_OUTPUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "chen_er_diagram.svg")

# ---------------------------------------------------------------------------
# Canvas & design tokens
# ---------------------------------------------------------------------------
W, H = 2260, 1620
TOP = 150  # vertical offset: leaves a clean header band above the diagram

TOKENS = {
    "bg":            "#0b1020",
    "grid":          "#161e36",
    "ink":           "#e8edf7",   # primary text
    "ink_muted":     "#8b97b3",   # secondary text
    "line":          "#7f8db0",   # structural connectors
    "line_attr":     "#3d4a6b",   # attribute connectors
    "entity_fill":   "#15305f",
    "entity_stroke": "#5b9bff",
    "weak_fill":     "#2a1d57",
    "weak_stroke":   "#a98bff",
    "rel_fill":      "#0d3a3a",
    "rel_stroke":    "#37c9b0",
    "id_fill":       "#43152a",
    "id_stroke":     "#ff7a95",
    "attr_fill":     "#131b30",
    "attr_stroke":   "#46557a",
    "key":           "#f4b942",   # primary key + required attributes
    "key_fill":      "#2e2410",
    "partial":       "#ff7a95",
    "derived":       "#5cc8ff",
    "multi":         "#a98bff",
    "total":         "#5b9bff",
    "card":          "#7dd3fc",
}
T = TOKENS

FONT = "'Inter','Segoe UI','Helvetica Neue',Arial,sans-serif"

# Type scale (px): 28 / 14 / 16 / 13 / 12
CHAR_W_ATTR = 6.6   # approx glyph width at 12px
CHAR_W_REL = 7.8    # approx glyph width at 13px bold

# ---------------------------------------------------------------------------
# Geometry registry (used to clip connectors to shape outlines)
# ---------------------------------------------------------------------------
NODES = {}


def add_node(nid, kind, x, y, a, b):
    """kind: rect | ell | dia ; a, b = half-width / half-height of the OUTER outline."""
    NODES[nid] = (kind, x, y, a, b)


def center(nid):
    _, x, y, _, _ = NODES[nid]
    return x, y


def edge_point(nid, tx, ty):
    kind, x, y, a, b = NODES[nid]
    dx, dy = tx - x, ty - y
    if dx == 0 and dy == 0:
        return x, y
    if kind == "rect":
        s = 1 / max(abs(dx) / a, abs(dy) / b)
    elif kind == "ell":
        s = 1 / math.sqrt((dx / a) ** 2 + (dy / b) ** 2)
    else:  # diamond
        s = 1 / (abs(dx) / a + abs(dy) / b)
    return x + dx * s, y + dy * s


def connector(n1, n2):
    """Return the clipped segment between two registered nodes."""
    c1, c2 = center(n1), center(n2)
    return edge_point(n1, *c2), edge_point(n2, *c1)


# ---------------------------------------------------------------------------
# Shape renderers (pure: take coordinates, return SVG strings)
# ---------------------------------------------------------------------------
def txt(x, y, s, cls):
    return f'<text class="{cls}" x="{x:.1f}" y="{y:.1f}" dy=".35em">{escape(s)}</text>'


def d_entity(x, y, w, h, label=""):
    return (
        f'<rect x="{x - w/2}" y="{y - h/2}" width="{w}" height="{h}" rx="4" '
        f'fill="{T["entity_fill"]}" stroke="{T["entity_stroke"]}" stroke-width="2"/>'
        + (txt(x, y, label, "t-entity") if label else "")
    )


def d_weak(x, y, w, h, label=""):
    return (
        f'<rect x="{x - w/2}" y="{y - h/2}" width="{w}" height="{h}" rx="4" '
        f'fill="{T["weak_fill"]}" stroke="{T["weak_stroke"]}" stroke-width="2"/>'
        f'<rect x="{x - w/2 + 6}" y="{y - h/2 + 6}" width="{w - 12}" height="{h - 12}" rx="2" '
        f'fill="none" stroke="{T["weak_stroke"]}" stroke-width="1.5"/>'
        + (txt(x, y, label, "t-entity") if label else "")
    )


def d_rel(x, y, a, b, label="", identifying=False):
    pts = f"{x},{y-b} {x+a},{y} {x},{y+b} {x-a},{y}"
    fill, stroke = (T["id_fill"], T["id_stroke"]) if identifying else (T["rel_fill"], T["rel_stroke"])
    out = f'<polygon points="{pts}" fill="{fill}" stroke="{stroke}" stroke-width="2" stroke-linejoin="round"/>'
    if identifying:
        ia, ib = a - 9, b - 8
        out += (
            f'<polygon points="{x},{y-ib} {x+ia},{y} {x},{y+ib} {x-ia},{y}" '
            f'fill="none" stroke="{stroke}" stroke-width="1.5" stroke-linejoin="round"/>'
        )
    return out + (txt(x, y, label, "t-rel") if label else "")


def attr_rx(label):
    return max(34, len(label) * CHAR_W_ATTR / 2 + 16)


ATTR_RY = 17


def d_attr(x, y, rx, ry, label="", kind="normal", required=False):
    stroke, fill, sw, dash = T["attr_stroke"], T["attr_fill"], 1.5, ""
    if required:
        stroke, fill = T["key"], T["key_fill"]
    if kind == "pk":
        stroke, fill, sw = T["key"], T["key_fill"], 2
    elif kind == "partial":
        stroke = T["partial"]
    elif kind == "multi":
        stroke = T["multi"]
    elif kind == "derived":
        stroke, dash = T["derived"], ' stroke-dasharray="5,4"'

    out = (
        f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rx:.1f}" ry="{ry}" fill="{fill}" '
        f'stroke="{stroke}" stroke-width="{sw}"{dash}/>'
    )
    if kind == "multi":
        out += (
            f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rx-5:.1f}" ry="{ry-4}" fill="none" '
            f'stroke="{stroke}" stroke-width="1.2"/>'
        )
    if label:
        out += txt(x, y, label, "t-attr")
        half = len(label) * CHAR_W_ATTR / 2 - 2
        if kind == "pk":
            out += (f'<line x1="{x-half:.1f}" y1="{y+9:.1f}" x2="{x+half:.1f}" y2="{y+9:.1f}" '
                    f'stroke="{T["key"]}" stroke-width="1.6"/>')
        elif kind == "partial":
            out += (f'<line x1="{x-half:.1f}" y1="{y+9:.1f}" x2="{x+half:.1f}" y2="{y+9:.1f}" '
                    f'stroke="{T["partial"]}" stroke-width="1.6" stroke-dasharray="4,3"/>')
    return out


# ---------------------------------------------------------------------------
# Diagram model
# ---------------------------------------------------------------------------
ENTITIES = []     # (id, x, y, w, h, weak)
RELS = []         # (id, x, y, a, b, identifying)
LINKS = []        # (entity, rel, cardinality, total)
ATTRS = []        # (id, parent, label, x, y, kind, required)


def entity(eid, x, y, w=170, h=56, weak=False):
    ENTITIES.append((eid, x, y, w, h, weak))
    add_node(eid, "rect", x, y, w / 2, h / 2)


def rel(rid, x, y, identifying=False):
    a = len(rid) * 4.9 + 26 + (10 if identifying else 0)
    b = 40 if identifying else 38
    RELS.append((rid, x, y, a, b, identifying))
    add_node(rid, "dia", x, y, a, b)


def link(ent, rid, card, total=False):
    LINKS.append((ent, rid, card, total))


def attr(parent, label, x, y, kind="normal", required=False, aid=None):
    aid = aid or f"{parent}.{label}"
    rx = attr_rx(label)
    ATTRS.append((aid, parent, label, x, y, kind, required, rx))
    add_node(aid, "ell", x, y, rx, ATTR_RY)
    return aid


def arc(parent, labels, cx, cy, rx, ry, angles):
    """Place attributes on an elliptical arc around (cx, cy). Angle 0 = right, 90 = down."""
    for spec, ang in zip(labels, angles):
        label, kind, req = (spec + (None, None))[:3] if isinstance(spec, tuple) else (spec, "normal", False)
        kind = kind or "normal"
        a = math.radians(ang)
        attr(parent, label, cx + rx * math.cos(a), cy + ry * math.sin(a), kind, bool(req))


def build():
    # ---- Strong entities --------------------------------------------------
    entity("HOSTEL", 420, 340)
    entity("MESS", 1560, 340)
    entity("STUDENT", 940, 770, w=190, h=60)
    entity("MEAL_SLOT", 1830, 900, w=180)
    # ---- Weak entities ----------------------------------------------------
    entity("MESS_REBATE", 520, 1270, w=190, h=64, weak=True)
    entity("MONTHLY_BILL", 1200, 1270, w=190, h=64, weak=True)

    # ---- Relationships ----------------------------------------------------
    rel("RESIDES_IN", 680, 555)
    rel("HOUSES_MESS", 945, 340)
    rel("SUBSCRIBES", 1260, 555)
    rel("CONSUMES", 1440, 900)
    rel("APPLIES_FOR", 640, 1030, identifying=True)
    rel("GENERATED_FOR", 1240, 1030, identifying=True)

    link("HOSTEL", "RESIDES_IN", "1")
    link("STUDENT", "RESIDES_IN", "N", total=True)
    link("HOSTEL", "HOUSES_MESS", "1")
    link("MESS", "HOUSES_MESS", "N")
    link("STUDENT", "SUBSCRIBES", "M")
    link("MESS", "SUBSCRIBES", "N")
    link("STUDENT", "CONSUMES", "M")
    link("MESS", "CONSUMES", "N")
    link("MEAL_SLOT", "CONSUMES", "P")
    link("STUDENT", "APPLIES_FOR", "1")
    link("MESS_REBATE", "APPLIES_FOR", "N", total=True)
    link("STUDENT", "GENERATED_FOR", "1")
    link("MONTHLY_BILL", "GENERATED_FOR", "N", total=True)

    # ---- STUDENT attributes ----------------------------------------------
    attr("STUDENT", "Email", 700, 450)
    attr("STUDENT", "Registration_No", 860, 425, "pk", True)
    attr("STUDENT", "Room_No", 1020, 425, required=True)
    attr("STUDENT", "Veg_Non_Veg", 1180, 450, required=True)
    name_id = attr("STUDENT", "Name", 600, 745, required=True)
    attr(name_id, "First_Name", 400, 690)
    attr(name_id, "Last_Name", 400, 785)
    attr("STUDENT", "Phone_Number", 640, 865, "multi")
    attr("STUDENT", "Department", 1260, 690)
    attr("STUDENT", "Year_of_Study", 1285, 775)
    attr("STUDENT", "DOB", 850, 925)
    attr("STUDENT", "Age", 1030, 925, "derived")

    # ---- HOSTEL attributes -----------------------------------------------
    arc("HOSTEL",
        [("Hostel_ID", "pk"), "Hostel_Name", "Block_Code", "Gender_Type", "Warden_Name"],
        420, 340, 290, 200, [255, 185, 150, 220, 290])

    # ---- MESS attributes -------------------------------------------------
    arc("MESS",
        [("Mess_ID", "pk"), "Mess_Name", "Mess_Type", "Capacity", "Monthly_Base_Fee", "Rebate_Rate_Per_Day"],
        1560, 340, 340, 200, [265, 235, 295, 325, 355, 25])

    # ---- SUBSCRIBES (relationship attributes) ----------------------------
    attr("SUBSCRIBES", "Plan_Type", 1415, 585)
    attr("SUBSCRIBES", "Start_Date", 1415, 631)
    attr("SUBSCRIBES", "End_Date", 1415, 677)

    # ---- CONSUMES (relationship attributes) ------------------------------
    attr("CONSUMES", "Swipe_Timestamp", 1450, 1050)
    attr("CONSUMES", "Diet_Served", 1650, 1010)

    # ---- MEAL_SLOT attributes --------------------------------------------
    arc("MEAL_SLOT",
        [("Slot_ID", "pk"), "Slot_Name", "Timings", "Guest_Rate"],
        1830, 900, 290, 170, [300, 340, 20, 60])

    # ---- MESS_REBATE (weak) attributes -----------------------------------
    arc("MESS_REBATE",
        [("Rebate_No", "partial"), "Start_Date", "End_Date", "Reason", "Status", ("Leave_Days", "derived")],
        520, 1270, 290, 175, [190, 158, 126, 94, 62, 30])

    # ---- MONTHLY_BILL (weak) attributes ----------------------------------
    arc("MONTHLY_BILL",
        [("Billing_Month", "partial"), "Base_Fee", ("Rebate_Discount", "derived"),
         ("Net_Payable", "derived"), "Payment_Status"],
        1200, 1270, 300, 175, [175, 140, 105, 70, 35])


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------
def render_links():
    lines, pills = [], []
    for ent, rid, card, total in LINKS:
        (x1, y1), (x2, y2) = connector(ent, rid)
        if total:  # double line: wide coloured stroke with a background-coloured core
            lines.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
                         f'stroke="{T["total"]}" stroke-width="7"/>')
            lines.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
                         f'stroke="{T["bg"]}" stroke-width="3"/>')
        else:
            lines.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
                         f'stroke="{T["line"]}" stroke-width="2"/>')
        # cardinality pill: just off the entity edge, nudged perpendicular to the line
        L = math.hypot(x2 - x1, y2 - y1) or 1
        ux, uy = (x2 - x1) / L, (y2 - y1) / L
        px, py = x1 + ux * 34 - uy * 17, y1 + uy * 34 + ux * 17
        pills.append(
            f'<rect x="{px-12:.1f}" y="{py-11:.1f}" width="24" height="22" rx="11" fill="{T["bg"]}" '
            f'stroke="{T["card"]}" stroke-width="1.2"/>' + txt(px, py, card, "t-card")
        )
    return "\n".join(lines), "\n".join(pills)


def render_attr_lines():
    out = []
    for aid, parent, *_ in ATTRS:
        (x1, y1), (x2, y2) = connector(parent, aid)
        out.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
                   f'stroke="{T["line_attr"]}" stroke-width="1.3"/>')
    return "\n".join(out)


def render_legend(x, y):
    w, h = 500, 300
    out = [
        f'<g transform="translate({x},{y})">',
        f'<rect width="{w}" height="{h}" rx="10" fill="#101830" stroke="{T["line_attr"]}" stroke-width="1.2"/>',
        txt(24, 28, "How to read this diagram", "t-legend-title"),
    ]
    col_x = [24, 264]
    rows = [
        ("Entity", lambda cx, cy: d_entity(cx, cy, 44, 22)),
        ("Weak entity", lambda cx, cy: d_weak(cx, cy, 44, 24)),
        ("Relationship", lambda cx, cy: d_rel(cx, cy, 24, 14)),
        ("Identifying relationship", lambda cx, cy: d_rel(cx, cy, 24, 14, identifying=True)),
        ("Primary key", lambda cx, cy: d_attr(cx, cy, 24, 11, kind="pk")
         + f'<line x1="{cx-12}" y1="{cy+6}" x2="{cx+12}" y2="{cy+6}" stroke="{T["key"]}" stroke-width="1.5"/>'),
        ("Partial key", lambda cx, cy: d_attr(cx, cy, 24, 11, kind="partial")
         + f'<line x1="{cx-12}" y1="{cy+6}" x2="{cx+12}" y2="{cy+6}" stroke="{T["partial"]}" stroke-width="1.5" stroke-dasharray="3,2"/>'),
        ("Multivalued", lambda cx, cy: d_attr(cx, cy, 24, 11, kind="multi")),
        ("Derived", lambda cx, cy: d_attr(cx, cy, 24, 11, kind="derived")),
        ("Required attribute", lambda cx, cy: d_attr(cx, cy, 24, 11, required=True)),
        ("Total participation",
         lambda cx, cy: f'<line x1="{cx-24}" y1="{cy}" x2="{cx+24}" y2="{cy}" stroke="{T["total"]}" stroke-width="7"/>'
                        f'<line x1="{cx-24}" y1="{cy}" x2="{cx+24}" y2="{cy}" stroke="{T["bg"]}" stroke-width="3"/>'),
        ("Cardinality (1, N, M, P)",
         lambda cx, cy: f'<rect x="{cx-12}" y="{cy-11}" width="24" height="22" rx="11" fill="{T["bg"]}" '
                        f'stroke="{T["card"]}" stroke-width="1.2"/>' + txt(cx, cy, "N", "t-card")),
    ]
    per_col = 6
    for i, (label, drawer) in enumerate(rows):
        c, r = divmod(i, per_col)
        cx = col_x[c] + 30
        cy = 74 + r * 38
        out.append(drawer(cx, cy))
        out.append(txt(cx + 46, cy, label, "t-legend"))
    out.append("</g>")
    return "\n".join(out)


def create_svg():
    build()
    link_lines, pills = render_links()

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="100%" height="100%">',
        f'''<defs>
<style>
  text {{ font-family: {FONT}; text-anchor: middle; }}
  .t-title {{ font-size: 30px; font-weight: 700; fill: {T["ink"]}; text-anchor: start; }}
  .t-sub {{ font-size: 15px; fill: {T["ink_muted"]}; text-anchor: start; }}
  .t-entity {{ font-size: 16px; font-weight: 700; fill: {T["ink"]}; letter-spacing: .4px; }}
  .t-rel {{ font-size: 13px; font-weight: 600; fill: {T["ink"]}; }}
  .t-attr {{ font-size: 12px; fill: {T["ink"]}; }}
  .t-card {{ font-size: 13px; font-weight: 700; fill: {T["card"]}; }}
  .t-legend-title {{ font-size: 14px; font-weight: 700; fill: {T["ink"]}; text-anchor: start; }}
  .t-legend {{ font-size: 12px; fill: {T["ink_muted"]}; text-anchor: start; }}
</style>
<pattern id="dots" width="32" height="32" patternUnits="userSpaceOnUse">
  <circle cx="1.5" cy="1.5" r="1.2" fill="{T["grid"]}"/>
</pattern>
</defs>''',
        f'<rect width="{W}" height="{H}" fill="{T["bg"]}"/>',
        f'<rect width="{W}" height="{H}" fill="url(#dots)"/>',
        # Header
        f'<text class="t-title" x="64" y="70">Mess Management System</text>',
        f'<text class="t-sub" x="64" y="102">Entity-relationship diagram in Chen notation, '
        f'with weak entities, identifying relationships, and composite, multivalued and derived attributes.</text>',
        f'<line x1="64" y1="124" x2="{W-64}" y2="124" stroke="{T["line_attr"]}" stroke-width="1"/>',
        f'<g transform="translate(0,{TOP - 100})">',
        "<!-- attribute connectors (back layer) -->",
        render_attr_lines(),
        "<!-- structural connectors -->",
        link_lines,
    ]

    # Attributes (drawn before entities so connectors tuck underneath)
    for aid, parent, label, x, y, kind, req, rx in ATTRS:
        svg.append(d_attr(x, y, rx, ATTR_RY, label, kind, req))

    for eid, x, y, w, h, weak in ENTITIES:
        svg.append(d_weak(x, y, w, h, eid) if weak else d_entity(x, y, w, h, eid))

    for rid, x, y, a, b, ident in RELS:
        svg.append(d_rel(x, y, a, b, rid, ident))

    svg.append(pills)
    svg.append(render_legend(1700, 1130))
    svg.append("</g>")
    svg.append("</svg>")

    with open(SVG_OUTPUT, "w", encoding="utf-8") as f:
        f.write("\n".join(svg))
    print(f"[OK] Generated Chen ER Diagram SVG: {SVG_OUTPUT}")


if __name__ == "__main__":
    create_svg()