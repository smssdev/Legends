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

from decor import bit, decorate
from page_css import page_css

ROOT = Path(__file__).parent
SERIES = json.loads((ROOT / "series.json").read_text())
OUT = ROOT / "out"

KEYWORDS = ("const let var if else switch case break default return function for while do of in new "
            "typeof true false null undefined class import export from async await try catch throw").split()

TEXT = {
    "en": {
        "contents": "Contents", "part": "Part", "chapter": "Chapter", "sample": "sample chapter",
        "author": "Author Name", "edition": "First edition", "output": "Terminal",
        "rights": "All rights reserved. No part of this book may be reproduced in any form without written permission from the publisher, except for brief quotations in reviews.",
        "code": "The code in this book is tested with Node.js 22. Every listing and its output is produced from the files in the book’s code repository.",
        "trademarks": "JavaScript, Node.js and other names mentioned in this book are trademarks of their owners and are used for identification only.",
    },
    "ar": {
        "contents": "المحتويات", "part": "الجزء", "chapter": "الفصل", "sample": "فصل نموذجي",
        "author": "اسم المؤلف", "edition": "الطبعة الأولى", "output": "الطرفية",
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
        return (f'<div class="{cls}" dir="ltr"><div class="output-bar"><i></i><i></i><i></i>'
                f'<span class="output-title">{label}</span></div><pre>{printed}</pre></div>')

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
          <div class="tp-bit">{bit("happy")}</div>
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
            text = decorate(fill_code(src.read_text(), lang), lang, k)
            text = text.replace('<section class="chapter"', f'<section class="chapter" style="page: {cid}"', 1)
            chapters.append(text)
            label = TEXT[lang]["chapter"]
            titles.append((cid, f"{label} {k}: {ch[lang]}"))
    if not chapters:
        return None
    rtl = lang == "ar"
    doc = f"""<!doctype html><html lang="{lang}" dir="{'rtl' if rtl else 'ltr'}"><head><meta charset="utf-8">
<title>{book["title"][lang]}</title><link rel="stylesheet" href="../style/book.css"><style>{page_css(lang, book, titles)}</style></head>
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
