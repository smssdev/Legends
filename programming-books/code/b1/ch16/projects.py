"""Writes the solutions of chapter 16's practice projects (accessibility), in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

T = {
    "en": dict(
        lang='lang="en"',
        r_title="Recipe", r_h1="Bit’s lentil soup", r_alt="A bowl of orange lentil soup with lemon on the side",
        r_time="Ready in 30 minutes · Serves 4", r_save="Save recipe", r_print="Print",
        r_search="Search recipes", r_go="Search",
        ltr="", f_title="Join the club", f_h1="Join the coding club",
        f_name="Full name", f_email="Email", f_email_hint="We will only use it to send the meeting times.",
        f_send="Join", f_summary="Please fix 2 problems:", f_e_name="Enter your full name.",
        f_e_email="Enter an email like name@example.com.", f_ok="Welcome to the club!",
        q_title="FAQ", q_h1="Questions about the course",
        faq=[("Do I need to install anything?", "Only a browser and VS Code. Both are free."),
             ("How long does each chapter take?", "Most readers finish a chapter in two or three evenings, projects included."),
             ("What if I get stuck?", "Re-read the hint, use the debugging method from chapter 14, then ask the community.")],
    ),
    "ar": dict(
        lang='lang="ar" dir="rtl"',
        r_title="وصفة", r_h1="شوربة العدس عند بِت", r_alt="طبق شوربة عدس برتقالية وبجانبه ليمون",
        r_time="جاهزة في 30 دقيقة · تكفي 4 أشخاص", r_save="احفظ الوصفة", r_print="اطبع",
        r_search="ابحث في الوصفات", r_go="ابحث",
        ltr=' dir="ltr"', f_title="انضم إلى النادي", f_h1="انضم إلى نادي البرمجة",
        f_name="الاسم الكامل", f_email="البريد الإلكتروني", f_email_hint="سنستخدمه فقط لإرسال مواعيد اللقاءات.",
        f_send="انضم", f_summary="يُرجى تصحيح مشكلتين:", f_e_name="اكتب اسمك الكامل.",
        f_e_email="اكتب بريداً صحيحاً مثل name@example.com", f_ok="أهلاً بك في النادي!",
        q_title="أسئلة شائعة", q_h1="أسئلة عن الدورة",
        faq=[("هل أحتاج إلى تثبيت شيء؟", "متصفح وVS Code فقط، وكلاهما مجاني."),
             ("كم يستغرق كل فصل؟", "ينهي معظم القراء الفصل في أمسيتين أو ثلاث، مع المشاريع."),
             ("ماذا أفعل إن توقفت؟", "أعد قراءة التلميح، واتبع طريقة تصحيح الأخطاء من الفصل 14، ثم اسأل المجتمع.")],
    ),
}

BASE = '''      *, *::before, *::after { box-sizing: border-box; }
      body { margin: 0; padding: 24px; font-family: system-ui, "Segoe UI", Tahoma, sans-serif; background: #f5f5fb; color: #1e1b2e; line-height: 1.5; }
      h1 { color: #4338ca; margin-top: 0; }
      button { font: inherit; padding: 8px 18px; border: 0; border-radius: 999px; color: white; background: #4338ca; cursor: pointer; }
      :focus-visible { outline: 3px solid #db2777; outline-offset: 3px; }
'''

SOUP = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 160">
  <rect width="320" height="160" fill="#fef3c7"/>
  <ellipse cx="160" cy="92" rx="110" ry="46" fill="#ffffff" stroke="#e5e7eb" stroke-width="4"/>
  <ellipse cx="160" cy="86" rx="92" ry="32" fill="#f59e0b"/>
  <circle cx="132" cy="80" r="5" fill="#fde68a"/><circle cx="176" cy="92" r="4" fill="#fde68a"/><circle cx="196" cy="78" r="3" fill="#16a34a"/>
  <circle cx="276" cy="122" r="22" fill="#facc15" stroke="#ca8a04" stroke-width="4"/>
</svg>
'''


def page(t, title, style, body, script=None):
    tag = f'\n    <script src="{script}"></script>' if script else ""
    return f'''<!doctype html>
<html {t["lang"]}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{title}</title>
    <style>
{BASE}{style}    </style>
  </head>
  <body>
{body}{tag}
  </body>
</html>
'''


def write(lang, t):
    d = HERE / lang / "projects"
    d.mkdir(parents=True, exist_ok=True)
    (d / "soup.svg").write_text(SOUP)

    # 16.1 the recipe card, before and after
    (d / "recipe-before.html").write_text(page(t, t["r_title"], '''      .card { max-width: 26em; background: white; border-radius: 16px; overflow: hidden; }
      .card img { width: 100%; display: block; }
      .body { padding: 16px; }
      .time { color: #c4c4c4; }
      .btn { display: inline-block; padding: 8px 18px; border-radius: 999px; color: white; background: #4338ca; }
''', f'''    <div class="title">{t["r_h1"]}</div>
    <input placeholder="{t["r_search"]}"> <div class="btn">{t["r_go"]}</div>
    <div class="card">
      <img src="soup.svg">
      <div class="body">
        <div class="time">{t["r_time"]}</div>
        <div class="btn" onclick="alert('Saved')">{t["r_save"]}</div>
      </div>
    </div>'''))
    (d / "recipe.html").write_text(page(t, t["r_title"], '''      .search { display: flex; gap: 8px; align-items: center; margin-bottom: 16px; flex-wrap: wrap; }
      .search input { font: inherit; padding: 7px 10px; border: 2px solid #6b7280; border-radius: 8px; }
      .card { max-width: 26em; background: white; border-radius: 16px; overflow: hidden; }
      .card img { width: 100%; display: block; }
      .body { padding: 16px; }
      .card h2 { margin: 0 0 4px; }
      .time { color: #4b5563; margin: 0 0 12px; }
      .secondary { background: #e0e7ff; color: #312e81; }
''', f'''    <header>
      <form class="search" role="search">
        <label for="q">{t["r_search"]}</label>
        <input id="q" type="search">
        <button type="submit">{t["r_go"]}</button>
      </form>
    </header>
    <main>
      <h1>{t["r_h1"]}</h1>
      <article class="card">
        <img src="soup.svg" alt="{t["r_alt"]}">
        <div class="body">
          <p class="time">{t["r_time"]}</p>
          <button type="button">{t["r_save"]}</button>
          <button type="button" class="secondary">{t["r_print"]}</button>
        </div>
      </article>
    </main>'''))

    # 16.2 a form that explains its errors
    (d / "join.html").write_text(page(t, t["f_title"], '''      form { max-width: 24em; display: flex; flex-direction: column; gap: 4px; }
      label { font-weight: 700; margin-top: 10px; }
      input { font: inherit; padding: 8px 10px; border: 2px solid #6b7280; border-radius: 8px; }
      input[aria-invalid="true"] { border-color: #b91c1c; }
      .hint { color: #4b5563; margin: 0; font-size: 0.9rem; }
      .error { color: #b91c1c; margin: 0; font-weight: 700; }
      .error:empty { display: none; }
      #summary { background: #fee2e2; border-inline-start: 5px solid #b91c1c; padding: 10px 14px; border-radius: 8px; max-width: 24em; }
      #summary[hidden] { display: none; }
      #summary ul { margin: 4px 0 0; }
      #summary a { color: #7f1d1d; }
      #done { color: #047857; font-weight: 700; }
      button { margin-top: 14px; align-self: flex-start; }
''', f'''    <h1>{t["f_h1"]}</h1>
    <div id="summary" role="alert" tabindex="-1" hidden></div>
    <form id="join" novalidate>
      <label for="name">{t["f_name"]}</label>
      <input id="name" autocomplete="name" aria-describedby="name-error">
      <p class="error" id="name-error"></p>

      <label for="email">{t["f_email"]}</label>
      <input id="email" type="email" autocomplete="email"{t["ltr"]} aria-describedby="email-hint email-error">
      <p class="hint" id="email-hint">{t["f_email_hint"]}</p>
      <p class="error" id="email-error"></p>

      <button type="submit">{t["f_send"]}</button>
    </form>
    <p id="done" role="status"></p>''', "join.js"))
    (d / "join.js").write_text(f'''const form = document.querySelector("#join");
const summary = document.querySelector("#summary");
const done = document.querySelector("#done");

const rules = [
  {{ id: "name", message: "{t["f_e_name"]}", ok: (value) => value.trim().length >= 2 }},
  {{ id: "email", message: "{t["f_e_email"]}", ok: (value) => /^\\S+@\\S+\\.\\S+$/.test(value) }},
];

function showError(field, message) {{
  const input = document.querySelector("#" + field);
  const error = document.querySelector("#" + field + "-error");
  error.textContent = message;
  input.setAttribute("aria-invalid", message ? "true" : "false");
}}

form.addEventListener("submit", (event) => {{
  event.preventDefault();
  const problems = [];

  for (const rule of rules) {{
    const value = document.querySelector("#" + rule.id).value;
    if (rule.ok(value)) {{
      showError(rule.id, "");
    }} else {{
      showError(rule.id, rule.message);
      problems.push(rule);
    }}
  }}

  if (problems.length === 0) {{
    summary.hidden = true;
    done.textContent = "{t["f_ok"]}";
    return;
  }}

  const title = document.createElement("p");
  title.textContent = problems.length === 1 ? problems[0].message : "{t["f_summary"]}";
  const list = document.createElement("ul");
  for (const problem of problems) {{
    const link = document.createElement("a");
    link.href = "#" + problem.id;
    link.textContent = problem.message;
    const item = document.createElement("li");
    item.append(link);
    list.append(item);
  }}
  summary.replaceChildren(title);
  if (problems.length > 1) summary.append(list);
  summary.hidden = false;
  summary.focus();
}});
''')

    # 16.3 an accessible FAQ
    items = "\n".join(f'''      <h2>
        <button type="button" aria-expanded="false" aria-controls="answer-{i}">{q}</button>
      </h2>
      <div id="answer-{i}" class="answer" hidden>
        <p>{a}</p>
      </div>''' for i, (q, a) in enumerate(t["faq"], 1))
    (d / "faq.html").write_text(page(t, t["q_title"], '''      .faq { max-width: 30em; }
      .faq h2 { margin: 0 0 8px; font-size: 1.05rem; }
      .faq h2 button { width: 100%; text-align: start; border-radius: 12px; padding: 12px 16px; display: flex; justify-content: space-between; gap: 12px; }
      .faq h2 button::after { content: "+"; font-weight: 700; }
      .faq h2 button[aria-expanded="true"]::after { content: "−"; }
      .answer { background: white; border-radius: 12px; padding: 4px 16px; margin: -4px 0 12px; }
''', f'''    <h1>{t["q_h1"]}</h1>
    <div class="faq">
{items}
    </div>''', "faq.js"))
    (d / "faq.js").write_text('''const buttons = document.querySelectorAll(".faq button");

for (const button of buttons) {
  button.addEventListener("click", () => {
    const open = button.getAttribute("aria-expanded") === "true";
    const answer = document.querySelector("#" + button.getAttribute("aria-controls"));

    button.setAttribute("aria-expanded", String(!open));
    answer.hidden = open;
  });
}
''')


for lang, t in T.items():
    write(lang, t)
print("ok")
