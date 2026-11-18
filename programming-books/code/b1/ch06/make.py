"""Writes the chapter 6 examples (CSS) in English and Arabic. Run: python3 make.py

The profile page is the one from chapter 5, now linked to style.css.
"""
import shutil
from pathlib import Path

HERE = Path(__file__).parent
CH5 = HERE.parent / "ch05"

T = {
    "en": dict(lang='lang="en"', tip="Tip", warn="Watch out", note="Note",
               c_title="Selectors", c_h1="Bit’s reading list",
               c_p1="Books that every new developer should read.",
               c_items=["Code from Zero", "Senior Frontend Engineering", "Senior Backend Engineering"],
               c_new="New", c_feat="This list is updated every month.",
               k_title="Colours", k_h1="Colours", k_names=["Named: tomato", "Hex: #4338ca", "RGB: rgb(15, 118, 110)", "With transparency"],
               b_title="Box model", b_text="I am a box with padding, a border and a margin."),
    "ar": dict(lang='lang="ar" dir="rtl"', tip="نصيحة", warn="انتبه", note="ملاحظة",
               c_title="المحددات", c_h1="قائمة قراءة بِت",
               c_p1="كتب يجب أن يقرأها كل مطور جديد.",
               c_items=["البرمجة من الصفر", "هندسة الواجهات باحتراف", "هندسة الخوادم باحتراف"],
               c_new="جديد", c_feat="تُحدَّث هذه القائمة كل شهر.",
               k_title="الألوان", k_h1="الألوان", k_names=["اسم: tomato", "سداسي: #4338ca", "RGB: rgb(15, 118, 110)", "مع شفافية"],
               b_title="نموذج الصندوق", b_text="أنا صندوق له حشوة وحدود وهامش."),
}


def head(lang, title, css=""):
    style = f"\n    <style>\n{css}    </style>" if css else ""
    return f'''<!doctype html>
<html {lang}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{title}</title>{style}
  </head>'''


SELECTORS_CSS = '''      h1 {
        color: #4338ca;
      }
      .intro {
        font-style: italic;
      }
      #featured {
        background-color: #fef3c7;
      }
      li .badge {
        color: white;
        background-color: #db2777;
        font-size: 0.8rem;
      }
'''

COLORS_CSS = '''      p {
        padding: 8px;
        color: white;
      }
      .named { background-color: tomato; }
      .hex { background-color: #4338ca; }
      .rgb { background-color: rgb(15, 118, 110); }
      .alpha { background-color: rgba(67, 56, 202, 0.4); color: black; }
'''

BOX_CSS = '''      .box {
        width: 260px;
        padding: 20px;
        border: 6px solid #4338ca;
        margin: 30px;
        background-color: #eef2ff;
      }
'''

STYLE_CSS = '''/* 1. Colours and fonts for the whole page */
:root {
  --brand: #4338ca;
  --accent: #db2777;
  --soft: #eef2ff;
}

body {
  margin: 0;
  font-family: system-ui, sans-serif;
  line-height: 1.6;
  color: #1e1b2e;
  background-color: #f5f5fb;
}

/* 2. The header: a coloured band with the avatar */
header {
  text-align: center;
  padding: 32px 16px 24px;
  color: white;
  background-color: var(--brand);
}

header img {
  background-color: white;
  border-radius: 50%;
  padding: 8px;
}

header h1 {
  margin: 8px 0 0;
  font-size: 2rem;
}

header p {
  margin: 0 0 16px;
  opacity: 0.85;
}

/* 3. The menu: links that look like buttons */
nav a {
  display: inline-block;
  padding: 6px 16px;
  margin: 4px;
  border-radius: 999px;
  color: var(--brand);
  background-color: white;
  text-decoration: none;
  font-weight: 700;
}

/* 4. The content: white cards, centred */
main {
  max-width: 640px;
  margin: 24px auto;
  padding: 0 16px;
}

section {
  background-color: white;
  border-radius: 16px;
  padding: 8px 24px 16px;
  margin-bottom: 16px;
  box-shadow: 0 2px 8px rgba(30, 27, 46, 0.08);
}

h2 {
  color: var(--brand);
  border-bottom: 3px solid var(--soft);
  padding-bottom: 4px;
}

/* 5. Skills as coloured tags */
ul {
  padding: 0;
}

li {
  display: inline-block;
  list-style: none;
  padding: 4px 14px;
  margin: 4px;
  border-radius: 999px;
  color: white;
  background-color: var(--accent);
}

a {
  color: var(--accent);
}

footer {
  text-align: center;
  color: #5b5873;
  font-size: 0.9rem;
  padding-bottom: 24px;
}
'''


def pages(t):
    items = "\n".join(
        (f'        <li id="featured">{x} <span class="badge">{t["c_new"]}</span></li>' if i == 0 else f"        <li>{x}</li>")
        for i, x in enumerate(t["c_items"]))
    colors = "\n".join(f'    <p class="{c}">{n}</p>' for c, n in zip(["named", "hex", "rgb", "alpha"], t["k_names"]))
    return {
        "selectors.html": f'''{head(t["lang"], t["c_title"], SELECTORS_CSS)}
  <body>
    <h1>{t["c_h1"]}</h1>
    <p class="intro">{t["c_p1"]}</p>
    <ul>
{items}
    </ul>
    <p>{t["c_feat"]}</p>
  </body>
</html>
''',
        "colors.html": f'''{head(t["lang"], t["k_title"], COLORS_CSS)}
  <body>
    <h1>{t["k_h1"]}</h1>
{colors}
  </body>
</html>
''',
        "box.html": f'''{head(t["lang"], t["b_title"], BOX_CSS)}
  <body>
    <div class="box">{t["b_text"]}</div>
  </body>
</html>
''',
    }


for lang, t in T.items():
    d = HERE / lang
    d.mkdir(exist_ok=True)
    for name, text in pages(t).items():
        (d / name).write_text(text)
    # The chapter 5 profile, linked to its new stylesheet.
    profile = (CH5 / lang / "profile.html").read_text()
    profile = profile.replace("    <title>", '    <link rel="stylesheet" href="style.css">\n    <title>', 1)
    profile = profile.replace("Built by Sara, with HTML only.", "Built by Sara, with HTML and CSS.") \
                     .replace("بنتها سارة بـ HTML وحدها.", "بنتها سارة بـ HTML وCSS.")
    (d / "profile.html").write_text(profile)
    shutil.copy(CH5 / lang / "bit.svg", d / "bit.svg")
    css = STYLE_CSS
    if lang == "ar":
        css = css.replace("/* 1. Colours and fonts for the whole page */", "/* 1. ألوان الصفحة كلها وخطوطها */") \
                 .replace("/* 2. The header: a coloured band with the avatar */", "/* 2. الترويسة: شريط ملون فيه الصورة */") \
                 .replace("/* 3. The menu: links that look like buttons */", "/* 3. القائمة: روابط تبدو أزراراً */") \
                 .replace("/* 4. The content: white cards, centred */", "/* 4. المحتوى: بطاقات بيضاء في المنتصف */") \
                 .replace("/* 5. Skills as coloured tags */", "/* 5. المهارات وسوماً ملونة */") \
                 .replace("font-family: system-ui, sans-serif;", 'font-family: "Segoe UI", Tahoma, system-ui, sans-serif;')
    (d / "style.css").write_text(css)
print("ok")
