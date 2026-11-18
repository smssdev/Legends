"""Covers, always in colour.

  front_html(book, lang)   the 7 x 10 in front cover (the first page of the colour PDF edition)
  python3 cover.py         out/<book>-<lang>-cover.html: the full KDP wrap for the print edition
                           (back, spine and front with bleed), sized from the print PDF's page count

KDP wrap size: width = bleed + back + spine + front + bleed, height = bleed + 10 in + bleed,
with bleed 0.125 in and spine = pages x 0.002252 in (black-and-white interior on white paper).
Text on the spine is allowed only from 79 pages.
"""
import json
import re
import subprocess
from pathlib import Path

from decor import bit

ROOT = Path(__file__).parent
SERIES = json.loads((ROOT / "series.json").read_text())
OUT = ROOT / "out"
BLEED, TRIM_W, TRIM_H, PER_PAGE = 0.125, 7.0, 10.0, 0.002252

WORDS = {
    "en": {"book": "Book", "learn": "What you will learn", "author": "Soliman Maged Saeed Salah",
           "code": "Every example is tested code. Download them all from the book’s repository.",
           "tracks": ["HTML", "CSS", "JavaScript", "Git"]},
    "ar": {"book": "الكتاب", "learn": "ماذا ستتعلم", "author": "سليمان ماجد سعيد صلاح",
           "code": "كل مثال كود حقيقي مُختبر، وكلها في مستودع الكتاب.",
           "tracks": ["HTML", "CSS", "JavaScript", "Git"]},
}
ORDINAL_AR = ["الأول", "الثاني", "الثالث", "الرابع", "الخامس", "السادس"]

CODE_BG = """const age = 9;
let price;
if (age < 4) {
  price = 0;
} else if (age < 13) {
  price = 6;
} else {
  price = 10;
}
console.log(`Pay $${price}`);
const isMember = true;
const day = "Tuesday";
if (isMember && day === "Tuesday") {
  price = price / 2;
}"""

STYLE = """
.cv { position: relative; overflow: hidden; color: #fff; font-family: var(--head);
  background: radial-gradient(circle at 80% 18%, #8b5cf6 0, transparent 45%),
              linear-gradient(150deg, #312e81 0%, #4338ca 38%, #7c3aed 72%, #db2777 120%); }
.cv * { text-align: start; }
.cv .bgcode { position: absolute; inset: 0.35in; font: 400 11pt/1.7 var(--mono); color: rgba(255,255,255,0.08); white-space: pre; direction: ltr; text-align: left; overflow: hidden; }
.cv .ring { position: absolute; border-radius: 50%; border: 18pt solid rgba(255,255,255,0.07); }
.front-in { position: absolute; inset: 0.5in 0.5in 0.45in; display: flex; flex-direction: column; }
.cv-series { align-self: flex-start; font: 700 9pt var(--head); letter-spacing: 0.14em; text-transform: uppercase;
  background: rgba(255,255,255,0.16); border-radius: 20pt; padding: 4pt 12pt; }
:root:lang(ar) .cv-series { letter-spacing: 0; font-size: 10pt; }
.cv-title { font: 700 50pt/1.04 var(--head); margin: 0.3in 0 0.12in; color: #fff; }
:root:lang(ar) .cv-title { font-size: 46pt; line-height: 1.3; }
.cv-sub { font: 600 14pt/1.45 var(--head); color: #e0e7ff; max-width: 5.2in; margin: 0; }
.cv-mid { flex: 1; position: relative; }
.cv-bit { position: absolute; inset-inline-end: -0.05in; bottom: 0.05in; width: 2.6in; z-index: 1; }
.cv-card { position: absolute; inset-inline-start: 0; top: 0.5in; background: #16142a; border-radius: 10pt; padding: 0 0 10pt;
  width: 3.05in; box-shadow: 0 10pt 24pt rgba(0,0,0,0.35); direction: ltr; }
.cv-card .bar { display: flex; gap: 5pt; padding: 7pt 10pt; background: #2a2745; border-radius: 10pt 10pt 0 0; }
.cv-card .bar i { width: 7pt; height: 7pt; border-radius: 50%; background: #f87171; display: block; }
.cv-card .bar i:nth-child(2) { background: #fbbf24; } .cv-card .bar i:nth-child(3) { background: #34d399; }
.cv-card pre { margin: 0; padding: 9pt 12pt 0; font: 400 10.5pt/1.6 var(--mono); color: #e7e5ff; white-space: pre; text-align: left; }
.cv-card .k { color: #c4b5fd; font-weight: 700; } .cv-card .s { color: #86efac; } .cv-card .n { color: #fdba74; }
.cv-tracks { position: absolute; z-index: 2; inset-inline-start: 0; bottom: 0.25in; display: flex; gap: 7pt; direction: ltr; }
:root:lang(ar) .cv-tracks { flex-direction: row-reverse; }
.cv-tracks span { font: 700 10pt var(--mono); background: #fff; color: #4338ca; border-radius: 8pt; padding: 5pt 10pt; }
.cv-tracks span:nth-child(2) { color: #db2777; } .cv-tracks span:nth-child(3) { color: #ca8a04; } .cv-tracks span:nth-child(4) { color: #0f766e; }
.cv-foot { display: flex; align-items: center; justify-content: space-between; gap: 10pt; }
.cv-level { font: 700 11pt var(--head); background: #f97316; color: #fff; border-radius: 20pt; padding: 5pt 14pt; }
.cv-author { font: 700 15pt var(--head); color: #fff; }

.back-in { position: absolute; inset: 0.55in 0.5in 0.45in; display: flex; flex-direction: column; gap: 12pt; }
.back-in p.blurb { font: 400 12pt/1.6 var(--body); color: #fff; margin: 0; text-align: justify; }
:root:lang(ar) .back-in p.blurb { font-size: 12.5pt; line-height: 1.9; }
.back-in h3 { font: 700 13pt var(--head); color: #fde68a; margin: 6pt 0 0; }
.back-in ul { list-style: none; margin: 0; padding: 0; }
.back-in li { font: 600 11pt/1.5 var(--head); padding: 4pt 0; padding-inline-start: 20pt; position: relative; }
.back-in li::before { content: "✓"; position: absolute; inset-inline-start: 0; color: #34d399; font-weight: 700; }
.back-in .note { font: 400 9.5pt/1.5 var(--head); color: #e0e7ff; margin: 0; }
.back-bit { width: 1.15in; }
.barcode { position: absolute; right: 0.5in; bottom: 0.45in; width: 2in; height: 1.2in; background: #fff; border-radius: 4pt; }
:root:lang(ar) .cv-sub, :root:lang(ar) .back-in li { font-family: var(--body); font-weight: 700; }
.spine { position: relative; display: flex; align-items: center; justify-content: center; background: #1e1b4b; }
.spine-text { transform: rotate(90deg); white-space: nowrap; font: 700 11pt var(--head); color: #fff; display: flex; gap: 18pt; }
"""


def _code_card():
    lines = ['<span class="k">const</span> age = <span class="n">9</span>;',
             '<span class="k">let</span> price;',
             '',
             '<span class="k">if</span> (age &lt; <span class="n">13</span>) {',
             '  price = <span class="n">6</span>;',
             '} <span class="k">else</span> {',
             '  price = <span class="n">10</span>;',
             '}',
             '',
             'console.log(<span class="s">"Hello, coder!"</span>);']
    return ('<div class="cv-card"><div class="bar"><i></i><i></i><i></i></div><pre>'
            + "\n".join(lines) + '</pre></div>')


def front_html(book, lang):
    w = WORDS[lang]
    n = int(book["id"][1:])
    book_no = f'{w["book"]} {n}' if lang == "en" else f'{w["book"]} {ORDINAL_AR[n - 1]}'
    tracks = "".join(f"<span>{t}</span>" for t in w["tracks"])
    return f"""<div class="front-in">
  <p class="cv-series">{SERIES["series"][lang]} · {book_no}</p>
  <h1 class="cv-title">{book["title"][lang]}</h1>
  <p class="cv-sub">{book["subtitle"][lang]}</p>
  <div class="cv-mid">{_code_card()}<div class="cv-tracks">{tracks}</div><div class="cv-bit">{bit("happy")}</div></div>
  <div class="cv-foot"><span class="cv-level">{book["level"][lang]}</span><span class="cv-author">{w["author"]}</span></div>
</div>"""


def decor_layer():
    rings = ('<div class="ring" style="width:4.2in;height:4.2in;right:-1.4in;top:-1.2in"></div>'
             '<div class="ring" style="width:3in;height:3in;left:-1.2in;bottom:1.2in"></div>')
    return f'<div class="bgcode">{CODE_BG}\n{CODE_BG}</div>{rings}'


def back_html(book, lang):
    w = WORDS[lang]
    blurb = book.get("blurb", {}).get(lang, book["reader"][lang])
    learn = "".join(f"<li>{x}</li>" for x in book.get("learn", {}).get(lang, []))
    return f"""<div class="back-in">
  <div class="back-bit">{bit("wow", wave=False)}</div>
  <p class="blurb">{blurb}</p>
  <h3>{w["learn"]}</h3><ul>{learn}</ul>
  <p class="note">{w["code"]}</p>
</div><div class="barcode"></div>"""


def pages_of(pdf):
    info = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True).stdout
    return int(re.search(r"Pages:\s+(\d+)", info).group(1))


def wrap(book, lang):
    pdf = OUT / f'{book["id"]}-{lang}-print.pdf'
    pages = pages_of(pdf)
    spine = pages * PER_PAGE
    width = 2 * BLEED + 2 * TRIM_W + spine
    height = 2 * BLEED + TRIM_H
    spine_text = ""
    if pages >= 79:
        spine_text = f'<div class="spine-text"><span>{book["title"][lang]}</span><span>{WORDS[lang]["author"]}</span></div>'
    panel = f"width:{TRIM_W + BLEED}in;height:{height}in"
    front = f'<div class="cv" style="{panel}">{decor_layer()}<div style="position:absolute;inset:{BLEED}in {BLEED}in {BLEED}in 0">{front_html(book, lang)}</div></div>'
    back = f'<div class="cv" style="{panel}">{decor_layer()}<div style="position:absolute;inset:{BLEED}in 0 {BLEED}in {BLEED}in">{back_html(book, lang)}</div></div>'
    if lang == "ar":
        # A right-to-left book opens the other way: laid flat, its front is on the left.
        front = front.replace(f"inset:{BLEED}in {BLEED}in {BLEED}in 0", f"inset:{BLEED}in 0 {BLEED}in {BLEED}in")
        back = back.replace(f"inset:{BLEED}in 0 {BLEED}in {BLEED}in", f"inset:{BLEED}in {BLEED}in {BLEED}in 0")
        panels = front + f'<div class="spine" style="width:{spine}in;height:{height}in">{spine_text}</div>' + back
    else:
        panels = back + f'<div class="spine" style="width:{spine}in;height:{height}in">{spine_text}</div>' + front
    doc = f"""<!doctype html><html lang="{lang}" dir="{'rtl' if lang == 'ar' else 'ltr'}"><head><meta charset="utf-8">
<title>{book["title"][lang]}: cover</title><link rel="stylesheet" href="../style/book.css">
<style>@page {{ size: {width:.4f}in {height}in; margin: 0; }} body {{ margin: 0; }} .row {{ display: flex; direction: ltr; }}{STYLE}</style></head>
<body><div class="row">{panels}</div></body></html>"""
    path = OUT / f'{book["id"]}-{lang}-cover.html'
    path.write_text(doc)
    return path, pages, width, height, spine


if __name__ == "__main__":
    for book in SERIES["books"]:
        for lang in ("en", "ar"):
            if (OUT / f'{book["id"]}-{lang}-print.pdf').exists():
                path, pages, w, h, s = wrap(book, lang)
                print(f"built {path.name}: {pages} pages, spine {s:.3f} in, cover {w:.3f} x {h} in")
