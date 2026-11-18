"""Writes the chapter 7 examples (Flexbox and Grid) in English and Arabic. Run: python3 make.py

Every demo uses only logical directions, so the same CSS works for both languages.
"""
import shutil
from pathlib import Path

HERE = Path(__file__).parent
CH6 = HERE.parent / "ch06"

T = {
    "en": dict(lang='lang="en"', menu=["Home", "Articles", "Videos", "About"], logo="Bit’s Blog",
               cards=["HTML", "CSS", "JavaScript", "Git", "Node.js", "DevTools"],
               center="Perfectly centred!", t_flex="Flexbox", t_center="Centring", t_grid="Grid gallery",
               t_layout="Page layout", head="Header", side="Sidebar", main="Main content", foot="Footer",
               start="justify-content: flex-start", between="justify-content: space-between", centre="justify-content: center"),
    "ar": dict(lang='lang="ar" dir="rtl"', menu=["الرئيسية", "المقالات", "الفيديو", "من نحن"], logo="مدونة بِت",
               cards=["HTML", "CSS", "JavaScript", "Git", "Node.js", "DevTools"],
               center="في المنتصف تماماً!", t_flex="Flexbox", t_center="التوسيط", t_grid="معرض بالشبكة",
               t_layout="تخطيط الصفحة", head="الترويسة", side="الشريط الجانبي", main="المحتوى الرئيسي", foot="التذييل",
               start="justify-content: flex-start", between="justify-content: space-between", centre="justify-content: center"),
}


def head(lang, title, css):
    return f'''<!doctype html>
<html {lang}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{title}</title>
    <style>
{css}    </style>
  </head>'''


FLEX_CSS = '''      body { font-family: system-ui, sans-serif; margin: 16px; }
      .bar {
        display: flex;
        gap: 8px;
        padding: 8px;
        margin-bottom: 4px;
        background-color: #eef2ff;
        border-radius: 10px;
      }
      .bar a {
        padding: 6px 12px;
        border-radius: 8px;
        color: white;
        background-color: #4338ca;
        text-decoration: none;
      }
      .start { justify-content: flex-start; }
      .between { justify-content: space-between; }
      .centre { justify-content: center; }
      code { display: block; margin: 12px 0 4px; color: #5b5873; }
'''

CENTER_CSS = '''      body {
        margin: 0;
        min-height: 260px;
        display: flex;
        justify-content: center;
        align-items: center;
        background-color: #eef2ff;
        font-family: system-ui, sans-serif;
      }
      .card {
        padding: 24px 32px;
        border-radius: 16px;
        color: white;
        background-color: #db2777;
        font-size: 1.4rem;
        font-weight: 700;
      }
'''

GRID_CSS = '''      body { font-family: system-ui, sans-serif; margin: 16px; }
      .gallery {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
        gap: 12px;
      }
      .gallery div {
        padding: 28px 8px;
        text-align: center;
        border-radius: 12px;
        color: white;
        background-color: #7c3aed;
        font-weight: 700;
      }
'''

LAYOUT_CSS = '''      body { font-family: system-ui, sans-serif; margin: 12px; }
      .page {
        display: grid;
        grid-template-columns: 180px 1fr;
        grid-template-areas:
          "head head"
          "side main"
          "foot foot";
        gap: 10px;
      }
      .page > * { padding: 20px; border-radius: 10px; color: white; font-weight: 700; }
      header { grid-area: head; background-color: #4338ca; }
      aside  { grid-area: side; background-color: #0f766e; }
      main   { grid-area: main; background-color: #db2777; min-height: 120px; }
      footer { grid-area: foot; background-color: #ea580c; }

      /* On narrow screens: one column */
      @media (max-width: 600px) {
        .page {
          grid-template-columns: 1fr;
          grid-template-areas: "head" "main" "side" "foot";
        }
      }
'''

PROFILE_EXTRA = '''
/* 6. Chapter 7: layout with Flexbox and Grid */
*,
*::before,
*::after {
  box-sizing: border-box;
}

header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 8px 24px;
}

header nav {
  flex-basis: 100%;
}

main {
  max-width: 900px;
  display: grid;
  gap: 16px;
}

section {
  margin-bottom: 0;
}

ul {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

li {
  margin: 0;
}

/* Wide screens: avatar beside the name, cards in two columns */
@media (min-width: 700px) {
  header {
    justify-content: flex-start;
    text-align: start;
    padding-inline: 48px;
  }

  main {
    grid-template-columns: 1fr 1fr;
  }

  #about {
    grid-column: 1 / -1;
  }
}
'''


def pages(t):
    links = "".join(f'<a href="#">{m}</a>' for m in t["menu"])
    cards = "\n".join(f"      <div>{c}</div>" for c in t["cards"])
    return {
        "flex.html": f'''{head(t["lang"], t["t_flex"], FLEX_CSS)}
  <body>
    <code>{t["start"]}</code>
    <nav class="bar start">{links}</nav>
    <code>{t["between"]}</code>
    <nav class="bar between">{links}</nav>
    <code>{t["centre"]}</code>
    <nav class="bar centre">{links}</nav>
  </body>
</html>
''',
        "center.html": f'''{head(t["lang"], t["t_center"], CENTER_CSS)}
  <body>
    <div class="card">{t["center"]}</div>
  </body>
</html>
''',
        "grid.html": f'''{head(t["lang"], t["t_grid"], GRID_CSS)}
  <body>
    <div class="gallery">
{cards}
    </div>
  </body>
</html>
''',
        "layout.html": f'''{head(t["lang"], t["t_layout"], LAYOUT_CSS)}
  <body>
    <div class="page">
      <header>{t["head"]}</header>
      <aside>{t["side"]}</aside>
      <main>{t["main"]}</main>
      <footer>{t["foot"]}</footer>
    </div>
  </body>
</html>
''',
    }


for lang, t in T.items():
    d = HERE / lang
    d.mkdir(exist_ok=True)
    for name, text in pages(t).items():
        (d / name).write_text(text)
    shutil.copy(CH6 / lang / "profile.html", d / "profile.html")
    shutil.copy(CH6 / lang / "bit.svg", d / "bit.svg")
    extra = PROFILE_EXTRA
    if lang == "ar":
        extra = extra.replace("/* 6. Chapter 7: layout with Flexbox and Grid */", "/* 6. الفصل 7: التخطيط بـ Flexbox وGrid */") \
                     .replace("/* Wide screens: avatar beside the name, cards in two columns */", "/* الشاشات العريضة: الصورة بجانب الاسم، والبطاقات في عمودين */")
    (d / "style.css").write_text((CH6 / lang / "style.css").read_text() + extra)
    (d / "layout-step.css").write_text(extra.lstrip("\n"))
print("ok")
