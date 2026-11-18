"""Builds the interior of each book as print-ready HTML, in English and Arabic.

  python3 build.py            -> out/<book>-<lang>.html for every book with chapters in src/
  node render.cjs             -> out/<book>-<lang>.pdf and out/preview/*.png

Chapter sources are HTML fragments in src/<book>/chNN.<lang>.html.
  <pre data-code="file.js"></pre>  inserts code/<book>/chNN/<lang>/file.js, highlighted
  <pre data-out="file.js"></pre>   runs that file with Node and inserts what it really prints
so every listing and every output in the book is the real, tested code.
"""
import html
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).parent
SERIES = json.loads((ROOT / "series.json").read_text())
OUT = ROOT / "out"

KEYWORDS = ("const let var if else switch case break default return function for while do of in new "
            "typeof true false null undefined class import export from async await try catch throw").split()

TEXT = {
    "en": {
        "contents": "Contents", "part": "Part", "chapter": "Chapter", "sample": "sample chapter",
        "author": "Author Name", "edition": "First edition", "output": "Output",
        "rights": "All rights reserved. No part of this book may be reproduced in any form without written permission from the publisher, except for brief quotations in reviews.",
        "code": "The code in this book is tested with Node.js 22. Every listing and its output is produced from the files in the book’s code repository.",
        "trademarks": "JavaScript, Node.js and other names mentioned in this book are trademarks of their owners and are used for identification only.",
    },
    "ar": {
        "contents": "المحتويات", "part": "الجزء", "chapter": "الفصل", "sample": "فصل نموذجي",
        "author": "اسم المؤلف", "edition": "الطبعة الأولى", "output": "المخرجات",
        "rights": "جميع الحقوق محفوظة. لا يجوز نسخ أي جزء من هذا الكتاب بأي شكل دون إذن كتابي من الناشر، إلا الاقتباسات القصيرة في المراجعات.",
        "code": "اختُبر الكود في هذا الكتاب على Node.js 22، وكل مثال ومخرجاته منسوخ من ملفات مستودع الكود الخاص بالكتاب.",
        "trademarks": "JavaScript وNode.js وغيرها من الأسماء الواردة في هذا الكتاب علامات تجارية لأصحابها، وتُذكر للتعريف فقط.",
    },
}

ORDINAL_AR = ["الأول", "الثاني", "الثالث", "الرابع", "الخامس", "السادس"]


def highlight_js(src):
    """Very small JavaScript highlighter: enough for a black-and-white book."""
    token = re.compile(r"(//[^\n]*)|(`(?:\\.|[^`])*`|\"(?:\\.|[^\"\n])*\"|'(?:\\.|[^'\n])*')|\b(\d+(?:\.\d+)?)\b|\b([A-Za-z_$][\w$]*)\b")
    out, pos = [], 0
    for m in token.finditer(src):
        out.append(html.escape(src[pos:m.start()]))
        text = html.escape(m.group(0))
        if m.group(1):
            out.append(f'<span class="c">{text}</span>')
        elif m.group(2):
            out.append(f'<span class="s">{text}</span>')
        elif m.group(3):
            out.append(f'<span class="n">{text}</span>')
        elif m.group(4) in KEYWORDS:
            out.append(f'<span class="k">{text}</span>')
        else:
            out.append(text)
        pos = m.end()
    out.append(html.escape(src[pos:]))
    return "".join(out)


def run_node(path):
    r = subprocess.run(["node", path.name], cwd=path.parent, capture_output=True, text=True, timeout=20)
    lines = (r.stdout + r.stderr).splitlines()
    keep = [l for l in lines if l.strip() and not l.lstrip().startswith("at ")
            and not l.startswith("Node.js") and str(path.parent) not in l]
    return "\n".join(keep)


def fill_code(chapter, lang):
    m = re.search(r'data-code="([^"]+)"', chapter)
    code_dir = ROOT / "code" / m.group(1)
    label = TEXT[lang]["output"]

    def code(m):
        attrs = m.group(1)
        f = re.search(r'data-code="([^"]+)"', attrs).group(1)
        title = re.search(r'data-title="([^"]+)"', attrs)
        head = f'<div class="listing-title">{title.group(1)}</div>' if title else ""
        src = (code_dir / f).read_text().rstrip("\n")
        return f'<div class="listing" dir="ltr">{head}<pre class="code">{highlight_js(src)}</pre></div>'

    def out(m):
        attrs = m.group(1)
        f = re.search(r'data-out="([^"]+)"', attrs).group(1)
        cls = "output error" if "error" in attrs else "output"
        printed = html.escape(run_node(code_dir / f))
        return f'<div class="{cls}" dir="ltr"><div class="output-title">{label}</div><pre>{printed}</pre></div>'

    chapter = re.sub(r'<pre (data-code="[^"]+"[^>]*)></pre>', code, chapter)
    chapter = re.sub(r'<pre (data-out="[^"]+"[^>]*)></pre>', out, chapter)
    return chapter


def front_matter(book, lang):
    t = TEXT[lang]
    series = SERIES["series"][lang]
    n = int(book["id"][1:])
    book_no = f"Book {n}" if lang == "en" else f"الكتاب {ORDINAL_AR[n - 1]}"
    pages = [
        f'<section class="front half-title"><p class="ht">{book["title"][lang]}</p></section>',
        f'''<section class="front title-page">
          <p class="tp-series">{series} · {book_no}</p>
          <h1 class="tp-title">{book["title"][lang]}</h1>
          <p class="tp-sub">{book["subtitle"][lang]}</p>
          <p class="tp-level">{book["level"][lang]}</p>
          <p class="tp-author">{t["author"]}</p>
        </section>''',
        f'''<section class="front copyright">
          <p><strong>{book["title"][lang]}</strong><br>{book["subtitle"][lang]}</p>
          <p>© 2026 {t["author"]}. {t["rights"]}</p>
          <p>{t["edition"]}, 2026</p>
          <p>{t["code"]}</p>
          <p>{t["trademarks"]}</p>
          <p>ISBN: ———</p>
        </section>''',
    ]
    toc, k = [], 0
    for i, part in enumerate(book["parts"], 1):
        toc.append(f'<li class="toc-part">{t["part"]} {i}: {part["title"][lang]}</li>')
        for ch in part["chapters"]:
            k += 1
            mark = f' <span class="toc-sample">({t["sample"]})</span>' if ch.get("sample") else ""
            toc.append(f'<li class="toc-ch"><span class="toc-n">{k}</span>{ch[lang]}{mark}</li>')
    pages.append(f'<section class="front toc"><h1>{t["contents"]}</h1><ol>{"".join(toc)}</ol></section>')
    return "".join(pages)


def css(lang, book, chapter_titles):
    rtl = lang == "ar"
    body = "'Noto Naskh Arabic', 'Source Serif 4', serif" if rtl else "'Source Serif 4', serif"
    head = "'Cairo', 'Inter', sans-serif" if rtl else "'Inter', sans-serif"
    # The gutter (binding side) is on the inside. A right-to-left book is bound on the right of its
    # first page, so the left/right margins swap.
    inner, outer = "0.875in", "0.625in"
    rec_l, rec_r = (outer, inner) if rtl else (inner, outer)
    named = "".join(
        f"""@page {cid} {{ @top-center {{ content: "{title}"; }} }}
        @page {cid}:first {{ @top-center {{ content: none; }} }}"""
        for cid, title in chapter_titles)
    return f"""
@font-face{{font-family:'Source Serif 4';font-weight:400;src:url(../fonts/source-serif-4-latin-400-normal.woff2)}}
@font-face{{font-family:'Source Serif 4';font-weight:600;src:url(../fonts/source-serif-4-latin-600-normal.woff2)}}
@font-face{{font-family:'Source Serif 4';font-weight:700;src:url(../fonts/source-serif-4-latin-700-normal.woff2)}}
@font-face{{font-family:Inter;font-weight:400;src:url(../fonts/inter-latin-400-normal.woff2)}}
@font-face{{font-family:Inter;font-weight:600;src:url(../fonts/inter-latin-600-normal.woff2)}}
@font-face{{font-family:Inter;font-weight:700;src:url(../fonts/inter-latin-700-normal.woff2)}}
@font-face{{font-family:'JetBrains Mono';font-weight:400;src:url(../fonts/jetbrains-mono-latin-400-normal.woff2)}}
@font-face{{font-family:'JetBrains Mono';font-weight:700;src:url(../fonts/jetbrains-mono-latin-700-normal.woff2)}}
@font-face{{font-family:'Noto Naskh Arabic';font-weight:400;src:url(../fonts/noto-naskh-arabic-arabic-400-normal.woff2)}}
@font-face{{font-family:'Noto Naskh Arabic';font-weight:700;src:url(../fonts/noto-naskh-arabic-arabic-700-normal.woff2)}}
@font-face{{font-family:Cairo;font-weight:600;src:url(../fonts/cairo-arabic-600-normal.woff2)}}
@font-face{{font-family:Cairo;font-weight:700;src:url(../fonts/cairo-arabic-700-normal.woff2)}}

@page {{ size: 7in 10in; margin: 0.8in {rec_r} 0.8in {rec_l};
  @top-center {{ content: "{book["title"][lang]}"; font: 600 8pt {head}; color: #555; }}
  @bottom-center {{ content: counter(page); font: 600 9pt {head}; }} }}
@page :left {{ margin-left: {rec_r}; margin-right: {rec_l}; }}
@page front {{ @top-center {{ content: none; }} @bottom-center {{ content: none; }} }}
{named}

html {{ font: 400 {"11pt" if rtl else "10.5pt"}/{"1.8" if rtl else "1.5"} {body}; color: #111; }}
body {{ margin: 0; }}
p {{ margin: 0 0 0.7em; text-align: justify; hyphens: auto; orphans: 3; widows: 3; }}
.front {{ page: front; break-after: page; }}
.half-title {{ display: flex; align-items: center; justify-content: center; height: 8.3in; }}
.ht {{ font: 700 22pt {head}; text-align: center; }}
.title-page {{ height: 8.3in; display: flex; flex-direction: column; justify-content: center; text-align: center; }}
.tp-series {{ font: 600 10pt {head}; letter-spacing: {"0" if rtl else "0.12em"}; text-transform: uppercase; color: #444; text-align: center; }}
.tp-title {{ font: 700 34pt/1.2 {head}; margin: 0.3in 0 0.15in; }}
.tp-sub {{ font: 400 14pt/1.5 {head}; color: #333; text-align: center; }}
.tp-level {{ font: 600 10pt {head}; border: 1.5pt solid #111; border-radius: 20pt; padding: 3pt 14pt; margin: 0.25in auto; text-align: center; }}
.tp-author {{ margin-top: 1.4in; font: 600 13pt {head}; text-align: center; }}
.copyright {{ display: flex; flex-direction: column; justify-content: flex-end; height: 8.3in; font-size: 8.5pt; color: #333; }}
.copyright p {{ text-align: start; }}
.toc h1 {{ font: 700 24pt {head}; margin: 0 0 0.3in; }}
.toc ol {{ list-style: none; padding: 0; margin: 0; }}
.toc-part {{ font: 700 10.5pt {head}; margin: 12pt 0 4pt; }}
.toc-ch {{ display: flex; gap: 10pt; padding: 2.5pt 0; border-bottom: 0.5pt dotted #999; }}
.toc-n {{ font: 600 9.5pt {head}; width: 18pt; }}
.toc-sample {{ font: 600 8.5pt {head}; color: #555; }}

.chapter {{ break-before: page; }}
.chapter-kicker {{ font: 700 11pt {head}; letter-spacing: {"0" if rtl else "0.14em"}; text-transform: uppercase; margin: 0.6in 0 4pt; text-align: start; }}
h1 {{ font: 700 26pt/1.25 {head}; margin: 0 0 0.3in; }}
h2 {{ font: 700 15pt/1.35 {head}; margin: 1.4em 0 0.5em; break-after: avoid; }}
h3 {{ font: 700 11.5pt/1.4 {head}; margin: 1.1em 0 0.4em; break-after: avoid; }}
dfn {{ font-style: normal; font-weight: 700; }}
code {{ font: 400 0.86em "JetBrains Mono", monospace; font-variant-ligatures: none; font-feature-settings: "liga" 0, "calt" 0; background: #eee; padding: 0.5pt 2.5pt; border-radius: 2pt; unicode-bidi: isolate; direction: ltr; }}
.lead {{ font-size: 1.08em; }}
ul, ol {{ margin: 0 0 0.8em; padding-inline-start: 1.4em; }}
li {{ margin-bottom: 0.25em; }}

.goals {{ border: 1.2pt solid #111; border-radius: 6pt; padding: 8pt 12pt 4pt; margin: 0 0 1.2em; break-inside: avoid; }}
.goals-title, .box-title, .next-title {{ font: 700 9.5pt {head}; margin: 0 0 4pt; text-align: start; }}
.goals ul {{ margin-bottom: 4pt; }}

.listing {{ margin: 0.8em 0 0.3em; break-inside: avoid; }}
.listing-title {{ font: 600 7.5pt 'JetBrains Mono', monospace; background: #111; color: #fff; display: inline-block; padding: 2pt 7pt; border-radius: 3pt 3pt 0 0; }}
pre {{ font: 400 8.6pt/1.5 "JetBrains Mono", monospace; font-variant-ligatures: none; font-feature-settings: "liga" 0, "calt" 0; margin: 0; white-space: pre-wrap; text-align: left; }}
pre.code {{ border: 1pt solid #111; border-radius: 0 4pt 4pt 4pt; padding: 7pt 9pt; }}
pre.plain {{ border: 1pt solid #111; border-radius: 4pt; padding: 7pt 9pt; margin: 0.6em 0; direction: ltr; }}
.k {{ font-weight: 700; }} .s {{ color: #444; }} .n {{ color: #000; }} .c {{ color: #666; font-style: italic; }}
.output {{ margin: 0 0 1em; background: #ececec; border-radius: 4pt; padding: 5pt 9pt 6pt; break-inside: avoid; }}
.output-title {{ font: 600 7pt {head}; color: #555; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 2pt; }}
.output pre {{ font-size: 8.4pt; }}
.output pre:lang(ar), .output pre {{ unicode-bidi: plaintext; }}
.output.error {{ background: #fff; border: 1pt dashed #111; }}

table {{ width: 100%; border-collapse: collapse; margin: 0.6em 0 1em; font-size: 0.9em; break-inside: avoid; }}
th {{ font: 700 8.5pt {head}; text-align: start; border-bottom: 1.2pt solid #111; padding: 3pt 5pt; }}
td {{ border-bottom: 0.5pt solid #aaa; padding: 3pt 5pt; vertical-align: top; }}

.box {{ border-inline-start: 3pt solid #111; background: #f2f2f2; padding: 7pt 11pt 2pt; margin: 1em 0; break-inside: avoid; }}
.box.warn {{ background: #fff; border: 1pt solid #111; border-inline-start-width: 3pt; }}
.box.rule {{ background: #111; color: #fff; border: none; border-radius: 4pt; }}
.box.rule code {{ background: #444; color: #fff; }}
.box.try {{ background: #fff; border: 1pt dashed #111; border-radius: 4pt; }}

figure {{ margin: 1em 0; text-align: center; break-inside: avoid; }}
figure svg {{ width: 88%; height: auto; }}
figcaption {{ font: 400 8.5pt/1.5 {head}; color: #444; margin-top: 4pt; }}

.summary li {{ margin-bottom: 0.35em; }}
.exercises .level {{ font: 700 7.5pt {head}; border: 1pt solid #111; border-radius: 8pt; padding: 0 6pt; margin-inline-end: 6pt; }}
.exercises li {{ margin-bottom: 0.5em; }}
.answers-note {{ font-size: 0.9em; color: #444; }}
.next {{ border-top: 1.5pt solid #111; margin-top: 1.4em; padding-top: 8pt; break-inside: avoid; }}
"""


def build(book, lang):
    chapters, titles = [], []
    k = 0
    for part in book["parts"]:
        for ch in part["chapters"]:
            k += 1
            src = ROOT / "src" / book["id"] / f"ch{k:02d}.{lang}.html"
            if not src.exists():
                continue
            cid = f"ch{k:02d}"
            text = fill_code(src.read_text(), lang)
            text = text.replace('<section class="chapter"', f'<section class="chapter" style="page: {cid}"', 1)
            chapters.append(text)
            label = TEXT[lang]["chapter"]
            titles.append((cid, f"{label} {k}: {ch[lang]}"))
    if not chapters:
        return None
    rtl = lang == "ar"
    doc = f"""<!doctype html><html lang="{lang}" dir="{'rtl' if rtl else 'ltr'}"><head><meta charset="utf-8">
<title>{book["title"][lang]}</title><style>{css(lang, book, titles)}</style></head>
<body>{front_matter(book, lang)}{"".join(chapters)}</body></html>"""
    OUT.mkdir(exist_ok=True)
    path = OUT / f"{book['id']}-{lang}.html"
    path.write_text(doc)
    return path


if __name__ == "__main__":
    for book in SERIES["books"]:
        for lang in ("en", "ar"):
            p = build(book, lang)
            if p:
                print("built", p.relative_to(ROOT))
