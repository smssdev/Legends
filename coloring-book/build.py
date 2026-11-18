"""Builds the sample pages of Book 1 as HTML (8.5x11 in, one SVG per page)."""
from pathlib import Path
from art import INK, duck, fish, butterfly, owl, flower, eye

HERE = Path(__file__).parent
PW, PH = 816, 1056  # 8.5 x 11 in at 96 px/in
F_HEAD, F_BODY = "Fredoka", "Andika"


def text(x, y, s, size, family=F_BODY, weight=400, anchor="middle", fill=INK, extra=""):
    return (f'<text x="{x}" y="{y}" font-family="{family}" font-weight="{weight}" font-size="{size}" '
            f'text-anchor="{anchor}" fill="{fill}" {extra}>{s}</text>')


def frame(title, instruction, n, tip, skill):
    return f"""
    <rect x="44" y="44" width="728" height="968" rx="30" fill="none" stroke="{INK}" stroke-width="4"/>
    <rect x="150" y="70" width="516" height="78" rx="39" fill="#fff" stroke="{INK}" stroke-width="5"/>
    {text(408, 124, title, 46, F_HEAD, 700)}
    {text(408, 200, instruction, 28, F_BODY, 700)}
    {text(84, 978, 'Grown-up tip: ' + tip, 14, anchor='start', fill='#444')}
    {text(732, 978, skill, 12, anchor='end', fill='#666')}
    <circle cx="408" cy="1012" r="20" fill="#fff" stroke="{INK}" stroke-width="3.5"/>
    {text(408, 1019, n, 18, F_HEAD, 600)}
    """


def box(x, y, w=74, h=74):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="#fff" stroke="{INK}" stroke-width="4.5"/>'


def three_path(x, y, k, dashed):
    d = "M10,20 C18,2 54,2 54,25 C54,42 40,48 28,48 C44,48 58,56 58,74 C58,100 18,102 6,84"
    if dashed:
        st = f'stroke="#8c8c8c" stroke-width="{6 / k}" stroke-dasharray="{1 / k} {11 / k}"'
        dot = f'<circle cx="10" cy="20" r="{7 / k}" fill="{INK}"/>'
    else:
        st = f'stroke="{INK}" stroke-width="{9 / k}"'
        dot = ""
    return (f'<g transform="translate({x},{y}) scale({k})"><path d="{d}" fill="none" {st} '
            f'stroke-linecap="round" stroke-linejoin="round"/>{dot}</g>')


def crayon(x, y, label, num=None):
    tip = f'<path d="M{x + 130},{y} L{x + 160},{y + 22} L{x + 130},{y + 44} Z" fill="#fff" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>'
    body = f'<rect x="{x}" y="{y}" width="130" height="44" rx="10" fill="#fff" stroke="{INK}" stroke-width="4"/>'
    lab = text(x + 65, y + 30, label, 22, F_BODY, 700)
    n = ""
    if num is not None:
        n = (f'<circle cx="{x - 30}" cy="{y + 22}" r="22" fill="#fff" stroke="{INK}" stroke-width="4"/>'
             + text(x - 30, y + 31, num, 26, F_HEAD, 700))
    return body + tip + lab + n


# ---------- pages ----------

def p_number3():
    out = frame("Number 3", "Color the big 3. Color 3 dots.", 1,
                "say “three” together and touch each dot as you count.", "Counting · K.CC.A.3, K.CC.B.4")
    out += text(250, 520, "3", 380, F_HEAD, 700, fill="#fff", extra=f'paint-order="stroke" stroke="{INK}" stroke-width="14" stroke-linejoin="round"')
    out += text(590, 330, "three", 96, F_HEAD, 700, fill="#fff", extra=f'paint-order="stroke" stroke="{INK}" stroke-width="9" stroke-linejoin="round"')
    for i in range(3):
        out += f'<circle cx="{500 + i * 90}" cy="430" r="36" fill="#fff" stroke="{INK}" stroke-width="5"/>'
    out += text(110, 600, "Trace the 3s. Start at the dot.", 26, weight=700, anchor="start")
    out += f'<line x1="90" y1="736" x2="726" y2="736" stroke="#bbb" stroke-width="2"/>'
    out += three_path(100, 626, 1.08, False)
    for i in range(5):
        out += three_path(215 + i * 104, 626, 1.08, True)
    out += text(110, 800, "Count and color 3 ducks.", 26, weight=700, anchor="start")
    for i in range(3):
        out += duck(120 + i * 205, 812, 1.42, flip=(i == 1))
    return out


def p_butterflies():
    out = frame("Butterfly Garden", "Color 4 butterflies.", 2,
                "let your child count out loud and stop at 4.", "Counting · K.CC.B.5")
    k = 1.75
    for r in range(2):
        for i in range(3):
            out += butterfly(118 + i * 205 + (r * 30 - 15), 245 + r * 245, k)
    out += text(110, 790, "How many butterflies are there in all?", 26, weight=700, anchor="start")
    out += box(590, 738, 90, 80)
    for i in range(5):
        out += flower(95 + i * 130, 840, 1.15)
    return out


def p_more():
    out = frame("Which Has More?", "Count each group. Circle the group with more.", 3,
                "line up the animals with your fingers to compare.", "Comparing · K.CC.C.6")

    def panel(x, y, kind, n):
        s = f'<rect x="{x}" y="{y}" width="310" height="250" rx="26" fill="#fff" stroke="{INK}" stroke-width="4"/>'
        spots = {2: [(60, 70), (170, 70)], 3: [(20, 30), (165, 30), (95, 130)],
                 4: [(25, 25), (165, 25), (25, 130), (165, 130)],
                 5: [(14, 30), (112, 30), (210, 30), (63, 135), (161, 135)]}[n]
        size = 0.86 if n == 5 else 1.1
        for i, (dx, dy) in enumerate(spots):
            s += kind(x + dx, y + dy, size, flip=(i % 2 == 1))
        s += text(x + 110, y + 296, "How many?", 20, weight=700)
        s += box(x + 200, y + 262, 64, 58)
        return s

    out += panel(76, 240, fish, 3) + panel(430, 240, fish, 5)
    out += panel(76, 590, duck, 4) + panel(430, 590, duck, 2)
    return out


def p_shapes():
    out = frame("Shape Town", "Color by shape.", 4,
                "help color each crayon in the key first, then match the shapes.", "Shapes · K.G.A.2")
    keys = [("circle", "yellow"), ("triangle", "red"), ("square", "blue")]
    for i, (shape, col) in enumerate(keys):
        x, y = 92 + i * 226, 246
        if shape == "circle":
            out += f'<circle cx="{x + 26}" cy="{y + 22}" r="24" fill="#fff" stroke="{INK}" stroke-width="4"/>'
        elif shape == "triangle":
            out += f'<path d="M{x},{y + 46} L{x + 52},{y + 46} L{x + 26},{y} Z" fill="#fff" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>'
        else:
            out += f'<rect x="{x + 4}" y="{y}" width="44" height="44" fill="#fff" stroke="{INK}" stroke-width="4"/>'
        out += f'<g transform="translate({x + 62},{y + 2}) scale(0.82)">{crayon(0, 0, col)}</g>'
    L = f'fill="#fff" stroke="{INK}" stroke-width="5" stroke-linejoin="round"'
    out += f'<line x1="70" y1="880" x2="746" y2="880" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>'
    # sun + balloons
    for a in range(8):
        import math
        t = a * math.pi / 4
        out += (f'<line x1="{640 + 72 * math.cos(t):.0f}" y1="{400 + 72 * math.sin(t):.0f}" x2="{640 + 98 * math.cos(t):.0f}" '
                f'y2="{400 + 98 * math.sin(t):.0f}" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>')
    out += f'<circle cx="640" cy="400" r="58" {L}/>'
    out += eye(622, 392, 6, 1) + eye(658, 392, 6, 1)
    out += f'<path d="M624,418 Q640,432 656,418" fill="none" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>'
    out += f'<path d="M440,430 Q452,500 430,560 M510,400 Q500,480 520,560" fill="none" stroke="{INK}" stroke-width="3"/>'
    out += f'<circle cx="440" cy="400" r="36" {L}/><circle cx="510" cy="366" r="36" {L}/>'
    # house
    out += f'<rect x="130" y="620" width="260" height="260" {L}/>'
    out += f'<path d="M108,622 L412,622 L260,452 Z" {L}/>'
    out += f'<circle cx="260" cy="566" r="30" {L}/>'
    out += f'<rect x="160" y="660" width="76" height="76" {L}/><rect x="284" y="660" width="76" height="76" {L}/>'
    out += f'<rect x="220" y="790" width="80" height="90" {L.replace("#fff", "#fff")}/>' if False else f'<rect x="216" y="792" width="88" height="88" {L}/>'
    out += f'<circle cx="286" cy="838" r="6" fill="{INK}"/>'
    # tree
    out += f'<rect x="592" y="822" width="58" height="58" {L}/>'
    out += f'<path d="M532,830 L710,830 L621,690 Z" {L}/><path d="M552,742 L690,742 L621,612 Z" {L}/>'
    # small bunny-free friend: duck
    out += duck(440, 760, 1.15, flip=True)
    return out


def p_owl():
    out = frame("Color by Number", "Find the number. Use its color.", 5,
                "point to a number, then find the same number in the key.", "Number recognition · K.CC.A.3")
    for i, (num, col) in enumerate([("1", "brown"), ("2", "orange"), ("3", "yellow"), ("4", "green")]):
        x = 112 + (i % 2) * 330
        y = 238 + (i // 2) * 64
        out += f'<g transform="translate({x},{y}) scale(0.9)">{crayon(0, 0, col, num)}</g>'
    out += owl(178, 392, 4.6, numbers=True)
    return out


def p_add():
    out = frame("Add It Up!", "Count all the animals. Write how many.", 6,
                "count the first group, then keep counting on.", "Adding within 5 · K.OA.A.1, K.OA.A.2")
    rows = [(fish, 2, 1), (butterfly, 1, 3), (duck, 2, 2)]
    for r, (kind, a, b) in enumerate(rows):
        y = 238 + r * 238

        def group(x, n):
            s = f'<rect x="{x}" y="{y}" width="236" height="190" rx="24" fill="#fff" stroke="{INK}" stroke-width="4"/>'
            k = 0.98 if n == 1 else 0.92 if n == 2 else 0.68
            w = 100 * k
            gap = max(4, (236 - n * w) / (n + 1))
            for i in range(n):
                xx = x + gap + i * (w + gap)
                if kind is butterfly:
                    s += butterfly(xx, y + 95 - w / 2, k)
                else:
                    s += kind(xx, y + 95 - w / 2, k, flip=(i % 2 == 1))
            return s
        out += group(66, a) + text(334, y + 118, "+", 72, F_HEAD, 700)
        out += group(366, b) + text(636, y + 118, "=", 72, F_HEAD, 700)
        out += box(672, y + 52, 90, 90)
    return out


PAGES = [p_number3, p_butterflies, p_more, p_shapes, p_owl, p_add]


def cover():
    C = {"duck": {"body": "#FFD23F", "beak": "#FF8C42", "blush": "#FF9AA2"},
         "fish": {"body": "#4CC9F0", "fin": "#3A86FF"},
         "bfly": {"wing": "#FF7AA2", "wing2": "#B388EB", "body": "#FFE08A"},
         "owl": {"body": "#B07444", "belly": "#F7B267", "eyes": "#FFF1B5", "leaf": "#6CCB5F"}}
    def num(x, y, n, fill, size=170):
        return text(x, y, n, size, F_HEAD, 700, fill=fill, extra=f'stroke="#fff" stroke-width="10" paint-order="stroke" stroke-linejoin="round"')
    s = f"""
    <defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#9FDcff"/><stop offset="0.62" stop-color="#E6F7FF"/><stop offset="1" stop-color="#FFF6D6"/></linearGradient></defs>
    <rect width="{PW}" height="{PH}" fill="url(#sky)"/>
    <circle cx="70" cy="560" r="0" fill="none"/>
    <path d="M0,820 Q200,740 420,800 Q640,860 816,770 L816,1056 L0,1056 Z" fill="#7BD389"/>
    <path d="M0,900 Q260,840 500,900 Q680,950 816,890 L816,1056 L0,1056 Z" fill="#5BBF6A"/>
    <rect x="200" y="58" width="416" height="46" rx="23" fill="#fff"/>
    {text(408, 90, 'LITTLE MATH ADVENTURES · BOOK 1', 21, F_HEAD, 600, fill='#3A86FF', extra='letter-spacing="1.5"')}
    {text(408, 205, 'My First Numbers', 82, F_HEAD, 700, fill='#FF5D8F', extra='stroke="#fff" stroke-width="12" paint-order="stroke" stroke-linejoin="round"')}
    {text(408, 300, '&amp; Counting', 82, F_HEAD, 700, fill='#3A86FF', extra='stroke="#fff" stroke-width="12" paint-order="stroke" stroke-linejoin="round"')}
    <rect x="178" y="330" width="460" height="62" rx="31" fill="#FF8C42" stroke="#fff" stroke-width="6"/>
    {text(408, 373, 'Coloring Workbook', 38, F_HEAD, 600, fill='#fff')}
    {text(408, 438, 'Trace · Count · Color · Shapes · First Adding', 25, F_BODY, 700, fill='#1F4E79')}
    {num(120, 690, '1', '#FF5D8F')}{num(235, 610, '2', '#FFB703')}{num(560, 630, '3', '#3A86FF')}
    {owl(250, 600, 3.1, C['owl'])}
    {butterfly(40, 455, 1.3, C['bfly'])}
    {butterfly(430, 470, 1.0, C['bfly'])}
    {duck(70, 830, 1.7, C['duck'])}
    {duck(600, 860, 1.4, C['duck'], flip=True)}
    {fish(640, 680, 1.1, C['fish'])}
    <circle cx="690" cy="530" r="66" fill="#FF5D8F" stroke="#fff" stroke-width="8"/>
    {text(690, 522, 'Ages', 26, F_HEAD, 600, fill='#fff')}
    {text(690, 562, '4–5', 42, F_HEAD, 700, fill='#fff')}
    <rect x="232" y="980" width="352" height="46" rx="23" fill="#fff"/>
    {text(408, 1012, 'Pre-K &amp; Kindergarten Readiness', 24, F_HEAD, 600, fill='#2B7A3A')}
    """
    return s


def html(svgs):
    pages = "".join(f'<div class="page"><svg viewBox="0 0 {PW} {PH}" width="{PW}" height="{PH}">{s}</svg></div>' for s in svgs)
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face{{font-family:Fredoka;font-weight:600;src:url(fonts/fredoka-latin-600-normal.woff2)}}
@font-face{{font-family:Fredoka;font-weight:700;src:url(fonts/fredoka-latin-700-normal.woff2)}}
@font-face{{font-family:Andika;font-weight:400;src:url(fonts/andika-latin-400-normal.woff2)}}
@font-face{{font-family:Andika;font-weight:700;src:url(fonts/andika-latin-700-normal.woff2)}}
@page{{size:8.5in 11in;margin:0}} html,body{{margin:0;background:#fff}}
.page{{width:8.5in;height:11in;page-break-after:always;overflow:hidden}} svg{{display:block}}
</style></head><body>{pages}</body></html>"""


if __name__ == "__main__":
    (HERE / "interior.html").write_text(html([p() for p in PAGES]))
    (HERE / "cover.html").write_text(html([cover()]))
    print("ok")
