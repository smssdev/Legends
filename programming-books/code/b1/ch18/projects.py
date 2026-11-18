"""Writes chapter 18's practice projects (the portfolio), in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

README = {
    "en": '''# My Tasks

A small, fast to-do list that works in any browser and remembers your tasks.

**Live:** https://sara-khan.github.io/my-tasks/

![My Tasks on a phone and a laptop](screenshot.png)

## Features

- Add, tick off, edit and delete tasks
- Filter: all, to do, done
- Progress bar, and a count of what is left
- English and Arabic, with right-to-left layout
- Saved in the browser with localStorage
- Works with the keyboard and screen readers

## Built with

HTML, CSS and JavaScript. No frameworks, no build step.

## Run it locally

1. Download or clone this repository.
2. Open `index.html` in your browser.

## What I learned

How to plan a project before coding, keep the data separate from the
display, and test a page with only the keyboard.
''',
    "ar": '''# مهامي

قائمة مهام صغيرة وسريعة، تعمل في أي متصفح وتتذكر مهامك.

**الرابط:** https://sara-khan.github.io/my-tasks/

![تطبيق مهامي على جوال وحاسوب](screenshot.png)

## المزايا

- إضافة المهام وإنجازها وتعديلها وحذفها
- التصفية: الكل، والمتبقية، والمنجزة
- شريط تقدّم، وعدد ما بقي
- العربية والإنجليزية، مع الاتجاه من اليمين إلى اليسار
- الحفظ في المتصفح بـ localStorage
- يعمل بلوحة المفاتيح وقارئ الشاشة

## بُني بـ

HTML وCSS وجافاسكربت، بلا أُطر عمل ولا خطوة بناء.

## تشغيله على جهازك

1. نزّل هذا المستودع أو انسخه بـ clone.
2. افتح `index.html` في متصفحك.

## ماذا تعلمت

كيف أخطط للمشروع قبل الكود، وأفصل البيانات عن العرض، وأختبر
الصفحة بلوحة المفاتيح وحدها.
''',
}

PLAN = {
    "en": '''# Plan: Water Buddy

## The problem
I forget to drink water when I study.

## Who it is for
Students who sit at a desk for hours.

## Must have (version 1)
- Set a daily goal in glasses
- One big button: "I drank a glass"
- Progress bar for today, reset every new day
- Saved in localStorage

## Nice to have (later)
- A reminder every hour
- A weekly chart
- Arabic and English

## Screens
1. Today: goal, progress, the big button
2. Settings: change the goal

## Data
{ goal: 8, today: "2026-05-01", glasses: 3 }

## Milestones
- Day 1: HTML and CSS, mobile first
- Day 2: the button and the progress bar
- Day 3: save, load, reset on a new day
- Day 4: keyboard test, contrast, README
- Day 5: publish on GitHub Pages, share the link
''',
    "ar": '''# خطة: رفيق الماء

## المشكلة
أنسى أن أشرب الماء حين أذاكر.

## لمن هو
الطلاب الذين يجلسون ساعات إلى المكتب.

## ضروري (الإصدار 1)
- ضبط هدف يومي بالأكواب
- زر واحد كبير: «شربت كوباً»
- شريط تقدّم لليوم، يبدأ من الصفر كل يوم جديد
- الحفظ في localStorage

## جميل لاحقاً
- تذكير كل ساعة
- رسم بياني للأسبوع
- العربية والإنجليزية

## الشاشات
1. اليوم: الهدف، والتقدّم، والزر الكبير
2. الإعدادات: تغيير الهدف

## البيانات
{ goal: 8, today: "2026-05-01", glasses: 3 }

## المراحل
- اليوم 1: HTML وCSS، للجوال أولاً
- اليوم 2: الزر وشريط التقدّم
- اليوم 3: الحفظ والتحميل والبدء من جديد كل يوم
- اليوم 4: اختبار لوحة المفاتيح، والتباين، وملف README
- اليوم 5: النشر على GitHub Pages ومشاركة الرابط
''',
}

T = {
    "en": dict(lang='lang="en"', title="Sara Khan · Web developer", name="Sara Khan",
               role="Junior web developer in Alexandria. I build small, accessible web apps.",
               cv="Download my CV", contact="Say hello", h_work="Selected work", live="Live", code="Code",
               projects=[("My Tasks", "A to-do app with filters, progress and two languages.", "#4338ca"),
                         ("Bit’s Quiz", "A quiz that builds itself from data.", "#db2777"),
                         ("Weather Report", "Loads data with fetch and survives errors.", "#059669")],
               h_skills="Skills", skills=["HTML", "CSS", "JavaScript", "Git & GitHub", "Accessibility", "Responsive design"]),
    "ar": dict(lang='lang="ar" dir="rtl"', title="سارة خان · مطورة ويب", name="سارة خان",
               role="مطورة ويب مبتدئة في الإسكندرية، أبني تطبيقات ويب صغيرة سهلة الوصول.",
               cv="نزّل سيرتي الذاتية", contact="راسلني", h_work="من أعمالي", live="جرّبه", code="الكود",
               projects=[("مهامي", "تطبيق مهام بتصفية وشريط تقدّم ولغتين.", "#4338ca"),
                         ("اختبار بِت", "اختبار يبني نفسه من البيانات.", "#db2777"),
                         ("تقرير الطقس", "يحمّل البيانات بـ fetch ويصمد أمام الأخطاء.", "#059669")],
               h_skills="المهارات", skills=["HTML", "CSS", "JavaScript", "Git وGitHub", "سهولة الوصول", "التصميم المتجاوب"]),
}


def portfolio(t):
    cards = "\n".join(f'''        <article class="project">
          <div class="thumb" style="--c: {c}" aria-hidden="true"></div>
          <h3>{n}</h3>
          <p>{d}</p>
          <p class="links"><a href="#">{t["live"]}</a> <a href="#">{t["code"]}</a></p>
        </article>''' for n, d, c in t["projects"])
    skills = "\n".join(f"        <li>{s}</li>" for s in t["skills"])
    return f'''<!doctype html>
<html {t["lang"]}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{t["title"]}</title>
    <style>
      *, *::before, *::after {{ box-sizing: border-box; }}
      :root {{ --brand: #4338ca; --ink: #1e1b2e; --muted: #5b5873; --soft: #eef2ff; }}
      body {{ margin: 0; font-family: system-ui, "Segoe UI", Tahoma, sans-serif; color: var(--ink); background: white; line-height: 1.5; }}
      main {{ max-width: 760px; margin: 0 auto; padding: 32px 20px; }}
      .hero {{ display: flex; align-items: center; gap: 20px; flex-wrap: wrap; }}
      .avatar {{ width: 96px; height: 96px; border-radius: 50%; background: linear-gradient(135deg, #4338ca, #db2777); color: white;
                display: grid; place-items: center; font-size: 2rem; font-weight: 700; }}
      h1 {{ margin: 0; color: var(--brand); }}
      .role {{ margin: 4px 0 12px; color: var(--muted); }}
      .actions {{ display: flex; gap: 8px; flex-wrap: wrap; }}
      .button {{ display: inline-block; padding: 8px 18px; border-radius: 999px; background: var(--brand); color: white; text-decoration: none; }}
      .button.secondary {{ background: var(--soft); color: var(--brand); }}
      h2 {{ margin-top: 36px; }}
      .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; }}
      .project {{ border: 1px solid #e0e0ee; border-radius: 16px; overflow: hidden; }}
      .project h3, .project p {{ margin: 8px 14px; }}
      .project p {{ color: var(--muted); font-size: 0.95rem; }}
      .thumb {{ height: 90px; background: var(--c); opacity: 0.85; }}
      .links {{ display: flex; gap: 14px; }}
      .links a {{ color: var(--brand); font-weight: 700; }}
      .skills {{ display: flex; flex-wrap: wrap; gap: 8px; list-style: none; padding: 0; }}
      .skills li {{ background: var(--soft); color: var(--brand); padding: 4px 12px; border-radius: 999px; }}
      :focus-visible {{ outline: 3px solid #db2777; outline-offset: 2px; }}
    </style>
  </head>
  <body>
    <main>
      <header class="hero">
        <div class="avatar" aria-hidden="true">{t["name"][0]}</div>
        <div>
          <h1>{t["name"]}</h1>
          <p class="role">{t["role"]}</p>
          <p class="actions">
            <a class="button" href="mailto:sara@example.com">{t["contact"]}</a>
            <a class="button secondary" href="cv.pdf">{t["cv"]}</a>
          </p>
        </div>
      </header>

      <h2>{t["h_work"]}</h2>
      <div class="grid">
{cards}
      </div>

      <h2>{t["h_skills"]}</h2>
      <ul class="skills">
{skills}
      </ul>
    </main>
  </body>
</html>
'''


for lang, t in T.items():
    d = HERE / lang / "projects"
    d.mkdir(parents=True, exist_ok=True)
    (d / "README.md").write_text(README[lang])
    (d / "plan.md").write_text(PLAN[lang])
    (d / "portfolio.html").write_text(portfolio(t))
print("ok")
