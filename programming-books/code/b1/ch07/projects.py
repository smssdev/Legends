"""Writes the solutions of chapter 7's practice projects (Flexbox and Grid), in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
import shutil
from pathlib import Path

HERE = Path(__file__).parent
CH6 = HERE.parent / "ch06"

T = {
    "en": dict(lang='lang="en"', g_title="Team", g_h1="Meet the team",
               people=[("Sara", "Frontend"), ("Omar", "Backend"), ("Huda", "Design"), ("Adam", "Mobile"), ("Lina", "Testing"), ("Youssef", "DevOps")],
               l_title="TaskFlow", l_brand="TaskFlow", l_nav=["Features", "Pricing", "Sign in"],
               l_h1="Plan your day in minutes", l_p="TaskFlow keeps your tasks, notes and deadlines in one simple place.",
               l_btn="Start for free", l_feat_h="Why TaskFlow?",
               feats=[("Simple", "Add a task in two seconds."), ("Everywhere", "On your phone and your laptop."), ("Private", "Your data stays yours.")],
               l_foot="© 2026 TaskFlow"),
    "ar": dict(lang='lang="ar" dir="rtl"', g_title="الفريق", g_h1="تعرّف على الفريق",
               people=[("سارة", "الواجهات"), ("عمر", "الخوادم"), ("هدى", "التصميم"), ("آدم", "الموبايل"), ("لينا", "الاختبار"), ("يوسف", "DevOps")],
               l_title="تاسك فلو", l_brand="تاسك فلو", l_nav=["المزايا", "الأسعار", "الدخول"],
               l_h1="خطط ليومك في دقائق", l_p="يحفظ تاسك فلو مهامك وملاحظاتك ومواعيدك في مكان واحد بسيط.",
               l_btn="ابدأ مجاناً", l_feat_h="لماذا تاسك فلو؟",
               feats=[("بسيط", "أضف مهمة في ثانيتين."), ("في كل مكان", "على هاتفك وحاسوبك."), ("خاص", "بياناتك تبقى لك.")],
               l_foot="© 2026 تاسك فلو"),
}

GALLERY_CSS = '''*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; padding: 20px; font-family: system-ui, "Segoe UI", Tahoma, sans-serif; background: #f5f5fb; }
h1 { color: #4338ca; }
.team {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 16px;
}
.person {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 18px 10px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(30, 27, 46, 0.08);
}
.avatar {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.6rem;
  font-weight: 700;
  color: white;
  background: #7c3aed;
}
.person p { margin: 0; color: #5b5873; }
'''

LANDING_CSS = '''*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; font-family: system-ui, "Segoe UI", Tahoma, sans-serif; color: #1e1b2e; }

/* Top bar: brand on one side, links on the other */
.bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 24px;
  border-bottom: 1px solid #eef2ff;
}
.brand { font-weight: 800; color: #4338ca; font-size: 1.3rem; }
.bar nav { display: flex; gap: 16px; }
.bar a { color: #1e1b2e; text-decoration: none; }

/* Hero: text and picture side by side */
.hero {
  display: flex;
  align-items: center;
  gap: 32px;
  padding: 40px 24px;
  background: #eef2ff;
}
.hero div { flex: 1; }
.hero h1 { font-size: 2.2rem; margin: 0 0 8px; }
.button { display: inline-block; padding: 10px 22px; border-radius: 999px; color: white; background: #db2777; text-decoration: none; font-weight: 700; }
.hero img { width: 180px; height: auto; }

/* Features: three columns */
.features { padding: 24px; }
.grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.grid article { padding: 16px; border-radius: 14px; background: #f5f5fb; }
.grid h3 { margin: 0 0 4px; color: #4338ca; }
footer { text-align: center; padding: 16px; color: #5b5873; }

/* Phones: everything in one column */
@media (max-width: 600px) {
  .hero { flex-direction: column; text-align: center; }
  .grid { grid-template-columns: 1fr; }
  .bar nav { gap: 10px; font-size: 0.9rem; }
}
'''

CAFE_LAYOUT = '''
/* Chapter 7: sections side by side on wide screens */
main {
  max-width: 900px;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
}

section {
  margin-bottom: 0;
}

nav {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
}
'''


def head(lang, title, css):
    return f'''<!doctype html>
<html {lang}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{title}</title>
    <link rel="stylesheet" href="{css}">
  </head>'''


for lang, t in T.items():
    d = HERE / lang / "projects"
    d.mkdir(parents=True, exist_ok=True)
    people = "\n".join(f'      <article class="person">\n        <div class="avatar">{n[0]}</div>\n        <h2>{n}</h2>\n        <p>{r}</p>\n      </article>' for n, r in t["people"])
    (d / "team.html").write_text(f'''{head(t["lang"], t["g_title"], "team.css")}
  <body>
    <h1>{t["g_h1"]}</h1>
    <main class="team">
{people}
    </main>
  </body>
</html>
'''.replace("<h2>", '<h2 style="margin:0;font-size:1.1rem">'))
    (d / "team.css").write_text(GALLERY_CSS)
    nav = "".join(f'<a href="#">{x}</a>' for x in t["l_nav"])
    feats = "\n".join(f"        <article>\n          <h3>{h}</h3>\n          <p>{p}</p>\n        </article>" for h, p in t["feats"])
    (d / "landing.html").write_text(f'''{head(t["lang"], t["l_title"], "landing.css")}
  <body>
    <header class="bar">
      <span class="brand">{t["l_brand"]}</span>
      <nav>{nav}</nav>
    </header>
    <section class="hero">
      <div>
        <h1>{t["l_h1"]}</h1>
        <p>{t["l_p"]}</p>
        <a class="button" href="#">{t["l_btn"]}</a>
      </div>
      <img src="bit.svg" alt="" width="180" height="210">
    </section>
    <section class="features">
      <h2>{t["l_feat_h"]}</h2>
      <div class="grid">
{feats}
      </div>
    </section>
    <footer>{t["l_foot"]}</footer>
  </body>
</html>
''')
    (d / "landing.css").write_text(LANDING_CSS)
    shutil.copy(HERE / lang / "bit.svg", d / "bit.svg")
    # The café from chapter 6, with a layout.
    (d / "cafe.html").write_text((CH6 / lang / "projects" / "cafe.html").read_text())
    (d / "cafe.css").write_text((CH6 / lang / "projects" / "cafe.css").read_text() + CAFE_LAYOUT)
print("ok")
