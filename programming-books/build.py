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
            "typeof true false null undefined class import export from async await try catch throw "
            "static extends super this yield instanceof finally type interface readonly satisfies keyof").split()
# PHP's own words (its variables start with $ and are left plain), and SQL's, which are written in capitals.
PHP_KEYWORDS = set(KEYWORDS) | set(("function fn foreach as elseif match enum public private protected abstract final "
                                    "namespace use declare require require_once include echo print array mixed int "
                                    "string bool float void never self parent clone implements trait list").split())
SQL_KEYWORDS = set(("SELECT FROM WHERE AND OR NOT NULL IS IN AS ON JOIN LEFT RIGHT INNER OUTER FULL GROUP BY ORDER "
                    "HAVING LIMIT OFFSET INSERT INTO VALUES UPDATE SET DELETE CREATE TABLE INDEX UNIQUE PRIMARY KEY "
                    "FOREIGN REFERENCES DEFAULT CHECK CONSTRAINT ALTER ADD DROP COLUMN BEGIN COMMIT ROLLBACK "
                    "RETURNING DISTINCT COUNT SUM AVG MIN MAX CASE WHEN THEN ELSE END EXISTS LIKE ILIKE BETWEEN "
                    "ASC DESC WITH OVER PARTITION FOR SHARE EXPLAIN ANALYZE TRUE FALSE CASCADE IF").split())

TEXT = {
    "en": {
        "contents": "Contents", "part": "Part", "preface": "How to Use This Book", "appendix": "Appendix", "answers": "Answers to the Exercises", "chapter": "Chapter", "sample": "sample chapter",
        "author": SERIES["author"]["en"], "edition": "First edition", "output": "Terminal", "no_errors": "(no errors: the types check)",
        "rights": "All rights reserved. No part of this book may be reproduced in any form without written permission from the publisher, except for brief quotations in reviews.",
        "code": "The code in this book is tested with Node.js 22. Every listing and its output is produced from the files in the book’s code repository.",
        "trademarks": "JavaScript, Node.js and other names mentioned in this book are trademarks of their owners and are used for identification only.",
    },
    "ar": {
        "contents": "المحتويات", "part": "الجزء", "preface": "كيف تستخدم هذا الكتاب", "appendix": "ملحق", "answers": "حلول التمارين", "chapter": "الفصل", "sample": "فصل نموذجي",
        "author": SERIES["author"]["ar"], "edition": "الطبعة الأولى", "output": "الطرفية", "no_errors": "(لا أخطاء: الأنواع سليمة)",
        "rights": "جميع الحقوق محفوظة. لا يجوز نسخ أي جزء من هذا الكتاب بأي شكل دون إذن كتابي من الناشر، إلا الاقتباسات القصيرة في المراجعات.",
        "code": "اختُبر الكود في هذا الكتاب على Node.js 22، وكل مثال ومخرجاته منسوخ من ملفات مستودع الكود الخاص بالكتاب.",
        "trademarks": "JavaScript وNode.js وغيرها من الأسماء الواردة في هذا الكتاب علامات تجارية لأصحابها، وتُذكر للتعريف فقط.",
    },
}

ORDINAL_AR = ["الأول", "الثاني", "الثالث", "الرابع", "الخامس", "السادس", "السابع", "الثامن", "التاسع", "العاشر",
              "الحادي عشر", "الثاني عشر", "الثالث عشر", "الرابع عشر", "الخامس عشر", "السادس عشر"]


def highlight_js(src, words=KEYWORDS, comment=r"//[^\n]*"):
    """Very small JavaScript highlighter: enough for a black-and-white book. PHP and SQL use it too, with
    their own keywords and comments."""
    token = re.compile(rf"({comment})|(`(?:\\.|[^`])*`|\"(?:\\.|[^\"\n])*\"|'(?:\\.|[^'\n])*')|\b(\d+(?:\.\d+)?)\b|\b([A-Za-z_$][\w$]*)\b")
    out, pos = [], 0
    for m in token.finditer(src):
        out.append(html.escape(src[pos:m.start()]))
        text = html.escape(m.group(0))
        if m.group(1):
            # Comments take their own direction, so an Arabic comment reads right to left.
            out.append(f'<span class="c line-bidi">{text}</span>')
        elif m.group(2):
            out.append(f'<span class="s">{text}</span>')
        elif m.group(3):
            out.append(f'<span class="n">{text}</span>')
        elif m.group(4) in words:
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
            # Comments take their own direction, so an Arabic comment reads right to left.
            out.append(f'<span class="c line-bidi">{text}</span>')
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
        elif re.match(r"\w+[=-]# ", line):
            # A psql prompt (shop=# or shop-# on continued lines), then the SQL that was typed.
            cut = line.index("# ") + 2
            lines.append(f'<span class="c">{html.escape(line[:cut])}</span><span class="k">{html.escape(line[cut:])}</span>')
        elif line.startswith("#"):
            # A comment line takes its own direction, so an Arabic comment reads right to left.
            lines.append(f'<span class="c line-bidi">{html.escape(line)}</span>')
        else:
            lines.append(html.escape(line))
    return "\n".join(lines)


def highlight(src, name):
    ext = name.rsplit(".", 1)[-1]
    if ext in ("js", "mjs", "cjs", "ts", "json"):
        return highlight_js(src)
    if ext in ("html", "css"):
        return highlight_markup(src, ext)
    if ext == "php":
        return highlight_js(src, PHP_KEYWORDS, r"//[^\n]*|#(?!\[)[^\n]*")
    if ext == "sql":
        return highlight_js(src, SQL_KEYWORDS, r"--[^\n]*")
    if ext in ("sh", "txt"):
        return highlight_shell(src)
    if ext == "md":
        # Markdown: headings in bold, everything else as written.
        return "\n".join(f"<b>{html.escape(l)}</b>" if l.startswith("#") else html.escape(l) for l in src.split("\n"))
    return html.escape(src)


def run_cached(cmd, path):
    """Runs a command for one example file, and remembers its output. The key is the content of every file
    in the example's folder and the folder above, so a change to the file or anything it reads runs it again.
    Every edition and language shares the result, and slow examples (a browser audit) run once per change."""
    digest = hashlib.md5(" ".join(cmd).encode())
    for folder in (path.parent, path.parent.parent):
        for f in sorted(folder.iterdir()):
            if f.is_file():
                digest.update(f.name.encode() + f.read_bytes())
    cache = OUT / ".runcache" / f"{digest.hexdigest()}.json"
    if cache.exists():
        return json.loads(cache.read_text())
    r = subprocess.run(cmd, cwd=path.parent, capture_output=True, text=True, timeout=120)
    result = {"out": r.stdout + r.stderr, "code": r.returncode}
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_text(json.dumps(result))
    return result


def run_node(path, stack=False):
    lines = run_cached(["node", path.name], path)["out"].splitlines()
    if stack:
        # Keep the stack trace, but only the reader's own code and without the build machine's paths.
        lines = [l.replace(str(path.parent) + "/", "") for l in lines if l.strip() and "node:internal" not in l
                 and not l.startswith("Node.js")]
        return "\n".join(lines)
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
            a = next(i for i, l in enumerate(lines) if l.strip().startswith("<body"))
            b = next(i for i, l in enumerate(lines) if l.strip() == "</body>")
            src = "\n".join(["  ..."] + lines[a:b + 1] + ["  ..."])
        part = re.search(r'data-from="([^"]+)"', attrs)
        if part:
            # Part of a long file, from the first line containing data-from to the first line after it
            # containing data-to (or, for data-to="^}#2", the second line that is exactly "}"); without
            # data-to, to the end of the file.
            lines = src.split("\n")
            start = next(i for i, l in enumerate(lines) if html.unescape(part.group(1)) in l)
            end = len(lines) - 1
            to = re.search(r'data-to="([^"]+)"', attrs)
            if to:
                want, _, nth = html.unescape(to.group(1)).partition("#")
                exact = want.startswith("^")
                hits = [i for i in range(start, len(lines))
                        if (lines[i] == want[1:] if exact else want in lines[i])]
                end = hits[int(nth or 1) - 1]
            src = "\n".join(lines[start:end + 1])
        cls = "code md" if f.endswith(".md") else "code"
        return f'<div class="listing" dir="ltr">{head}<pre class="{cls}">{highlight(src, f)}</pre></div>'

    def out(m):
        attrs = m.group(1)
        f = re.search(r'data-out="([^"]+)"', attrs).group(1)
        cls = "output error" if "error" in attrs else "output"
        printed = html.escape(run_node(code_dir / f, stack='data-stack' in attrs))
        return (f'<div class="{cls}" dir="ltr"><div class="output-bar"><i></i><i></i><i></i>'
                f'<span class="output-title">{label}</span></div><pre>{printed}</pre></div>')

    def check(m):
        # <pre data-check="file.ts"></pre>: what the TypeScript compiler says about the file, for real.
        attrs = m.group(1)
        f = re.search(r'data-check="([^"]+)"', attrs).group(1)
        path = code_dir / f
        tsc = next(d / "node_modules" / ".bin" / "tsc" for d in path.parents if (d / "node_modules" / ".bin" / "tsc").exists())
        r = run_cached([str(tsc), "--noEmit", "--strict", "--noUncheckedIndexedAccess", "--target", "es2024",
                        "--module", "nodenext", "--types", "node", "--jsx", "react-jsx", path.name], path)
        printed = r["out"].strip().replace(str(path.parent) + "/", "")
        lines = [f"$ npx tsc --noEmit {path.name}"] + ([printed] if printed else [TEXT[lang]["no_errors"]])
        cls = "output error" if r["code"] else "output"
        return (f'<div class="{cls}" dir="ltr"><div class="output-bar"><i></i><i></i><i></i>'
                f'<span class="output-title">{label}</span></div><pre>{html.escape(chr(10).join(lines))}</pre></div>')

    def shell(m):
        # <pre data-sh="npx vitest run sum.test.ts" data-in="dir"></pre>: runs a command (a test runner, say)
        # in the example folder and shows "$ command" with its real output. data-in picks a subfolder.
        attrs = html.unescape(m.group(1))
        cmd = re.search(r'data-sh="([^"]+)"', attrs).group(1)
        sub = re.search(r'data-in="([^"]+)"', attrs)
        folder = code_dir / (sub.group(1) if sub else ".")
        env_path = str(ROOT / "code" / "b2" / "node_modules" / ".bin")
        r = run_cached(["bash", "-c", f'PATH="{env_path}:$PATH" NO_COLOR=1 FORCE_COLOR=0 CI=1 {cmd}'], folder / "_")
        out = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", r["out"]).replace(str(folder) + "/", "").replace(str(folder), ".")
        noise = ("Start at", "Environment ", "create it once", "learn more", "Error Context:", "(node:", "(Use `node", "[WebServer]")
        lines = [l.rstrip() for l in out.splitlines() if l.strip() and not l.strip().startswith(noise)]
        text = "\n".join([f"$ {cmd}"] + lines)
        cls = "output error" if r["code"] else "output"
        return (f'<div class="{cls}" dir="ltr"><div class="output-bar"><i></i><i></i><i></i>'
                f'<span class="output-title">{label}</span></div><pre>{html.escape(text)}</pre></div>')

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

    def image(m):
        # <figure data-img="shots/products.png" data-url="/products" data-width="560">: a screenshot taken by the
        # example's own script (for apps that need a running server, such as Next.js), in a browser frame.
        attrs = m.group(1)
        f = re.search(r'data-img="([^"]+)"', attrs).group(1)
        width = int((re.search(r'data-width="(\d+)"', attrs) or re.match("(.*)", "560")).group(1))
        url = (re.search(r'data-url="([^"]+)"', attrs) or re.match("(.*)", f)).group(1)
        src = code_dir / f
        name = f"{code_dir.parent.parent.name}-{code_dir.parent.name}-{lang}-{f.replace('/', '-')}"
        target = OUT / "img" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists() or target.read_bytes() != src.read_bytes():
            target.write_bytes(src.read_bytes())
        bar = (f'<div class="browser-bar" dir="ltr"><i></i><i></i><i></i>'
               f'<span>{html.escape(url)}</span><b>{width}px</b></div>')
        return f'<figure class="browser">{bar}<img src="img/{name}" alt="">'

    chapter = re.sub(r'<figure (data-img="[^"]+"[^>]*)>', image, chapter)
    chapter = re.sub(r'<figure (data-render="[^"]+"[^>]*)>', page, chapter)
    chapter = re.sub(r'<pre (data-code="[^"]+"[^>]*)></pre>', code, chapter)
    chapter = re.sub(r'<pre (data-out="[^"]+"[^>]*)></pre>', out, chapter)
    chapter = re.sub(r'<pre (data-check="[^"]+"[^>]*)></pre>', check, chapter)
    chapter = re.sub(r'<pre (data-sh="[^"]+"[^>]*)></pre>', shell, chapter)
    return chapter


def edition_pill(book, lang):
    ed = book.get("edition")
    return f'<p class="tp-edition">{ed[lang]}</p>' if ed else ""


def front_matter(book, lang, pages_of=None):
    pages_of = pages_of or {}
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
    nums = pages_of
    def entry(key, label, title):
        page = nums.get(key, "")
        return f'<li class="toc-ch"><span class="toc-n">{label}</span><span class="toc-t">{title}</span><span class="toc-p">{page}</span></li>'
    def has(key):
        return any((ROOT / "src" / d / f"{key}.{lang}.html").exists() for d in (book["id"], book.get("shared") or "-"))
    if has("preface"):
        toc.append(entry("preface", "", t["preface"]))
    for i, part in enumerate(book["parts"], 1):
        toc.append(f'<li class="toc-part">{t["part"]} {i}: {part["title"][lang]}</li>')
        for ch in part["chapters"]:
            k += 1
            toc.append(entry(f"ch{k:02d}", k, ch[lang]))
    if has("answers"):
        toc.append(f'<li class="toc-part">{t["appendix"]}</li>')
        toc.append(entry("answers", "", t["answers"]))
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


def only_edition(text, book):
    """Shared chapters hold edition-specific parts between <!-- react --> and <!-- /react --> (or vue, node,
    laravel). Each edition keeps its own parts and drops the others'. The edition is the end of the book's id."""
    keep = book["id"].rsplit("-", 1)[-1]
    for fw in ("react", "vue", "node", "laravel"):
        block = re.compile(rf"<!-- {fw} -->(.*?)<!-- /{fw} -->\n?", re.S)
        text = block.sub((lambda m: m.group(1)) if fw == keep else "", text)
    return text


def answers_by_chapter(book, lang):
    """Book 2 and later keep each chapter's answers next to the chapter (src/<src>.answers.<lang>.html),
    so the appendix of each edition is put together here, with that edition's chapter numbers."""
    out, k = [], 0
    for part in book["parts"]:
        for ch in part["chapters"]:
            k += 1
            src = ROOT / "src" / f'{ch.get("src") or book["id"] + "/" + f"ch{k:02d}"}.answers.{lang}.html'
            if src.exists():
                body = re.sub(r"\{\{n(?:([+-]\d+))?\}\}", lambda m: str(k + int(m.group(1) or 0)), src.read_text())
                body = only_edition(body, book)
                out.append(f'<h2>{TEXT[lang]["chapter"]} {k}</h2>\n{body}')
    return "\n\n".join(out)


def build(book, lang, edition):
    """edition "color": full colour, cover first, equal margins, for reading as a PDF on a screen.
    edition "print": black and white, mirrored margins, the interior file for KDP (the cover is separate)."""
    chapters, titles = [], []
    k = 0
    for part in book["parts"]:
        for ch in part["chapters"]:
            k += 1
            # A chapter is read from src/<book>/chNN, or from the path in its "src" (shared chapters, such as
            # Book 2's language chapters, are written once for the React and Vue editions). In those,
            # {{n}} stands for the chapter's number, which differs between the editions.
            src = ROOT / "src" / (ch.get("src") or f'{book["id"]}/ch{k:02d}')
            src = src.with_name(f"{src.name}.{lang}.html")
            if not src.exists():
                continue
            cid = f"ch{k:02d}"
            text = re.sub(r"\{\{n(?:([+-]\d+))?\}\}", lambda m: str(k + int(m.group(1) or 0)), src.read_text())
            text = only_edition(text, book)
            text = decorate(fill_code(text, lang), lang, k)
            text = text.replace('<section class="chapter"', f'<section class="chapter" style="page: {cid}"', 1)
            chapters.append(text)
            label = TEXT[lang]["chapter"]
            titles.append((cid, f"{label} {k}: {ch[lang]}"))
    if not chapters:
        return None
    extra = {"preface": TEXT[lang]["preface"], "answers": TEXT[lang]["answers"]}
    for key, title in extra.items():
        src = ROOT / "src" / book["id"] / f"{key}.{lang}.html"
        shared = ROOT / "src" / (book.get("shared") or "-") / f"{key}.{lang}.html"
        if not src.exists() and shared.exists():
            src = shared
        if src.exists():
            text = src.read_text()
            if key == "answers" and "<!-- chapters -->" in text:
                text = text.replace("<!-- chapters -->", answers_by_chapter(book, lang))
            text = decorate(fill_code(only_edition(text, book), lang), lang, "")
            text = text.replace('<section class="chapter', f'<section style="page: {key}" class="chapter', 1)
            if key == "preface":
                chapters.insert(0, text)
            else:
                chapters.append(text)
            titles.append((key, title))
    rtl = lang == "ar"
    sheets = '<link rel="stylesheet" href="../style/book.css">'
    cover = ""
    if edition == "print":
        sheets += '<link rel="stylesheet" href="../style/print-bw.css">'
    else:
        cover = (f'<section class="cv" style="page: cover; width: 7in; height: 10in; break-after: page">'
                 f'{decor_layer()}{front_html(book, lang)}</section>')
    pages_file = OUT / f"{book['id']}-{lang}-{edition}.pages.json"
    pages_of = json.loads(pages_file.read_text()) if pages_file.exists() else {}
    body = cover + front_matter(book, lang, pages_of) + "".join(chapters)
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
