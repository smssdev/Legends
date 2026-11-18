"""Builds the interior of each book as print-ready HTML, in English and Arabic.

  python3 build.py            -> out/<book>-<lang>.html for every book with chapters in src/
  node render.cjs             -> out/<book>-<lang>.pdf and out/preview/*.png

Chapter sources are HTML fragments in src/<book>/chNN.<lang>.html.
  <pre data-code="file.js"></pre>  inserts code/<book>/chNN/<lang>/file.js, highlighted
  <pre data-out="file.js"></pre>   runs that file with Node and inserts what it really prints
so every listing and every output in the book is the real, tested code.
"""
import hashlib
import html
import json
import re
import subprocess
from pathlib import Path

from cover import STYLE as COVER_STYLE, decor_layer, front_html
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
        "author": SERIES["author"]["en"], "edition": "First edition", "output": "Terminal",
        "rights": "All rights reserved. No part of this book may be reproduced in any form without written permission from the publisher, except for brief quotations in reviews.",
        "code": "The code in this book is tested with Node.js 22. Every listing and its output is produced from the files in the book’s code repository.",
        "trademarks": "JavaScript, Node.js and other names mentioned in this book are trademarks of their owners and are used for identification only.",
    },
    "ar": {
        "contents": "المحتويات", "part": "الجزء", "chapter": "الفصل", "sample": "فصل نموذجي",
        "author": SERIES["author"]["ar"], "edition": "الطبعة الأولى", "output": "الطرفية",
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


def highlight_markup(src, kind):
    """HTML and CSS: tags and properties in the keyword colour, values and strings in the string colour."""
    if kind == "html":
        token = re.compile(r"(<!--.*?-->)|(</?[a-zA-Z][\w-]*|/?>)|(\b[a-zA-Z-]+(?==))|(\"[^\"]*\")", re.S)
    else:
        token = re.compile(r"(/\*.*?\*/)|([.#]?[a-zA-Z][\w-]*(?=\s*\{)|@[a-z-]+)|([a-z-]+(?=\s*:))|(:\s*[^;{}\n]+)", re.S)
    out, pos = [], 0
    for m in token.finditer(src):
        out.append(html.escape(src[pos:m.start()]))
        text = html.escape(m.group(0))
        if m.group(1):
            out.append(f'<span class="c">{text}</span>')
        elif m.group(2):
            out.append(f'<span class="k">{text}</span>')
        elif m.group(3):
            out.append(f'<span class="n">{text}</span>')
        else:
            out.append(f'<span class="s">{text}</span>')
        pos = m.end()
    out.append(html.escape(src[pos:]))
    return "".join(out)


def highlight_shell(src):
    """Terminal sessions: the prompt and the command stand out from what the computer answers."""
    lines = []
    for line in src.split("\n"):
        if line.startswith("$ ") or line.startswith("> "):
            lines.append(f'<span class="c">{html.escape(line[:2])}</span><span class="k">{html.escape(line[2:])}</span>')
        elif line.startswith("#"):
            lines.append(f'<span class="c">{html.escape(line)}</span>')
        else:
            lines.append(html.escape(line))
    return "\n".join(lines)


def highlight(src, name):
    ext = name.rsplit(".", 1)[-1]
    if ext in ("js", "json"):
        return highlight_js(src)
    if ext in ("html", "css"):
        return highlight_markup(src, ext)
    if ext in ("sh", "txt"):
        return highlight_shell(src)
    return html.escape(src)


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
        if 'data-show="body"' in attrs:
            # Long pages: show only the body; the head is the same skeleton as before.
            lines = src.split("\n")
            a = next(i for i, l in enumerate(lines) if l.strip() == "<body>")
            b = next(i for i, l in enumerate(lines) if l.strip() == "</body>")
            src = "\n".join(["  ..."] + lines[a:b + 1] + ["  ..."])
        return f'<div class="listing" dir="ltr">{head}<pre class="code">{highlight(src, f)}</pre></div>'

    def out(m):
        attrs = m.group(1)
        f = re.search(r'data-out="([^"]+)"', attrs).group(1)
        cls = "output error" if "error" in attrs else "output"
        printed = html.escape(run_node(code_dir / f))
        return (f'<div class="{cls}" dir="ltr"><div class="output-bar"><i></i><i></i><i></i>'
                f'<span class="output-title">{label}</span></div><pre>{printed}</pre></div>')

    def page(m):
        attrs = m.group(1)
        f = re.search(r'data-render="([^"]+)"', attrs).group(1)
        width = int((re.search(r'data-width="(\d+)"', attrs) or re.match("(.*)", "640")).group(1))
        src = code_dir / f
        actions = html.unescape((re.search(r'data-actions="([^"]*)"', attrs) or re.match("()", "")).group(1))
        tag = "-" + hashlib.md5(actions.encode()).hexdigest()[:6] if actions else ""
        name = f"{code_dir.parent.parent.name}-{code_dir.parent.name}-{lang}-{f.replace('/', '-')}-{width}{tag}.png"
        img = OUT / "img" / name
        img.parent.mkdir(parents=True, exist_ok=True)
        if not img.exists() or img.stat().st_mtime < max(src.stat().st_mtime, (ROOT / "shot.cjs").stat().st_mtime):
            subprocess.run(["node", str(ROOT / "shot.cjs"), str(src), str(img), str(width), actions], check=True)
        bar = (f'<div class="browser-bar" dir="ltr"><i></i><i></i><i></i>'
               f'<span>{html.escape(f.rsplit("/", 1)[-1])}</span><b>{width}px</b></div>')
        # Narrow (phone) screenshots are shown narrower, so they keep a phone's proportions.
        pct = min(100, round(width / 560 * 100))
        style = f' style="width: {pct}%; margin-inline: auto"' if pct < 100 else ""
        return f'<figure class="browser"{style}>{bar}<img src="img/{name}" alt="">'

    chapter = re.sub(r'<figure (data-render="[^"]+"[^>]*)>', page, chapter)
    chapter = re.sub(r'<pre (data-code="[^"]+"[^>]*)></pre>', code, chapter)
    chapter = re.sub(r'<pre (data-out="[^"]+"[^>]*)></pre>', out, chapter)
    return chapter


def edition_pill(book, lang):
    ed = book.get("edition")
    return f'<p class="tp-edition">{ed[lang]}</p>' if ed else ""


def front_matter(book, lang):
    t = TEXT[lang]
    series = SERIES["series"][lang]
    n = book["number"]
    book_no = f"Book {n}" if lang == "en" else f"الكتاب {ORDINAL_AR[n - 1]}"
    pages = [
        f'<section class="front half-title"><p class="ht">{book["title"][lang]}</p></section>',
        f'''<section class="front title-page">
          <p class="tp-series">{series} · {book_no}</p>
          <h1 class="tp-title">{book["title"][lang]}</h1>
          <p class="tp-sub">{book["subtitle"][lang]}</p>{edition_pill(book, lang)}
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


# Bit in greys for the black-and-white edition.
GREYS = {"#6366f1": "#a3a3a3", "#e0e7ff": "#f2f2f2", "#312e81": "#1a1a1a", "#818cf8": "#c8c8c8",
         "#fbbf24": "#e0e0e0", "#f472b6": "#8c8c8c", "#f9a8d4": "#d4d4d4", "#1e1b4b": "#111111",
         # figure palette
         "#4338ca": "#2b2b2b", "#0f766e": "#2b2b2b", "#ea580c": "#2b2b2b", "#7c3aed": "#2b2b2b",
         "#db2777": "#2b2b2b", "#16142a": "#262626", "#86efac": "#e8e8e8", "#e6f7f4": "#efefef",
         "#fff4ea": "#efefef", "#f5f0ff": "#efefef", "#fdf0f6": "#efefef", "#f7f8fc": "#f5f5f5"}
EDITIONS = ("color", "print")


def build(book, lang, edition):
    """edition "color": full colour, cover first, equal margins, for reading as a PDF on a screen.
    edition "print": black and white, mirrored margins, the interior file for KDP (the cover is separate)."""
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
    sheets = '<link rel="stylesheet" href="../style/book.css">'
    cover = ""
    if edition == "print":
        sheets += '<link rel="stylesheet" href="../style/print-bw.css">'
    else:
        cover = (f'<section class="cv" style="page: cover; width: 7in; height: 10in; break-after: page">'
                 f'{decor_layer()}{front_html(book, lang)}</section>')
    body = cover + front_matter(book, lang) + "".join(chapters)
    if edition == "print":
        for c, g in GREYS.items():
            body = body.replace(c, g)
    doc = f"""<!doctype html><html lang="{lang}" dir="{'rtl' if rtl else 'ltr'}"><head><meta charset="utf-8">
<title>{book["title"][lang]}</title>{sheets}<style>{page_css(lang, book, titles, edition)}{COVER_STYLE if cover else ""}</style></head>
<body>{body}</body></html>"""
    OUT.mkdir(exist_ok=True)
    path = OUT / f"{book['id']}-{lang}-{edition}.html"
    path.write_text(doc)
    return path


if __name__ == "__main__":
    for book in SERIES["books"]:
        for lang in ("en", "ar"):
            for edition in EDITIONS:
                p = build(book, lang, edition)
                if p:
                    print("built", p.relative_to(ROOT))
