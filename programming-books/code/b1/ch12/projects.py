"""Writes the solutions of chapter 12's practice projects (the DOM and events), in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

T = {
    "en": dict(
        lang='lang="en"',
        th_title="Night mode", th_h1="Bit’s reading room",
        th_p="Some people like bright pages; others read late at night. One button lets each reader choose.",
        th_dark="Switch to night", th_light="Switch to day",
        ch_title="Message box", ch_h1="Write a short message", ch_label="Your message",
        ch_left="characters left",
        ch_text="Learning JavaScript one small step at a time, and today the page finally answers back when I type!",
        qz_title="Quiz", qz_h1="Bit’s web quiz", qz_q="Question",
        qz_right="Correct!", qz_wrong="Not quite. The answer is", qz_score="Your score:",
        qz_again="Play again", qz_of="/", qz_end=".",
        questions=[
            ("Which language gives a page its structure?", ["CSS", "HTML", "JSON"], 1),
            ("Which method finds one element on the page?", ["querySelector", "console.log", "JSON.parse"], 0),
            ("Which event fires when a button is pressed?", ["input", "submit", "click"], 2),
        ],
    ),
    "ar": dict(
        lang='lang="ar" dir="rtl"',
        th_title="الوضع الليلي", th_h1="غرفة القراءة عند بِت",
        th_p="بعض الناس يحبون الصفحات المضيئة، وآخرون يقرؤون في آخر الليل. زر واحد يترك لكل قارئ أن يختار.",
        th_dark="الوضع الليلي", th_light="الوضع النهاري",
        ch_title="صندوق الرسالة", ch_h1="اكتب رسالة قصيرة", ch_label="رسالتك",
        ch_left="حرفاً متبقياً",
        ch_text="أتعلم جافاسكربت خطوة صغيرة كل يوم، واليوم صارت الصفحة ترد علي حين أكتب، وهذا شعور رائع جداً!",
        qz_title="اختبار", qz_h1="اختبار بِت في الويب", qz_q="السؤال",
        qz_right="إجابة صحيحة!", qz_wrong="ليس تماماً. الإجابة هي", qz_score="نتيجتك:",
        qz_again="العب مرة أخرى", qz_of="من", qz_end="",
        questions=[
            ("أي لغة تعطي الصفحة بنيتها؟", ["CSS", "HTML", "JSON"], 1),
            ("أي دالة تجد عنصراً واحداً في الصفحة؟", ["querySelector", "console.log", "JSON.parse"], 0),
            ("أي حدث يقع حين يُضغط زر؟", ["input", "submit", "click"], 2),
        ],
    ),
}

BASE = '''      *, *::before, *::after { box-sizing: border-box; }
      body { margin: 0; padding: 24px; font-family: system-ui, "Segoe UI", Tahoma, sans-serif; background: #f5f5fb; color: #1e1b4b; }
      h1 { color: #4338ca; margin-top: 0; }
      button { font: inherit; padding: 8px 18px; border: 0; border-radius: 999px; color: white; background: #4338ca; cursor: pointer; }
'''


def page(t, title, style, body, script):
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
{body}
    <script src="{script}"></script>
  </body>
</html>
'''


def write(lang, t):
    d = HERE / lang / "projects"
    d.mkdir(parents=True, exist_ok=True)

    # 12.1 night mode
    (d / "theme.html").write_text(page(t, t["th_title"], '''      body.dark { background: #1e1b4b; color: #e0e7ff; }
      body.dark h1 { color: #fbbf24; }
      body.dark button { background: #fbbf24; color: #1e1b4b; }
      p { max-width: 36em; line-height: 1.6; }
''', f'''    <h1>{t["th_h1"]}</h1>
    <p>{t["th_p"]}</p>
    <button id="theme">{t["th_dark"]}</button>''', "theme.js"))
    (d / "theme.js").write_text(f'''const button = document.querySelector("#theme");

button.addEventListener("click", () => {{
  document.body.classList.toggle("dark");

  const isDark = document.body.classList.contains("dark");
  button.textContent = isDark ? "{t["th_light"]}" : "{t["th_dark"]}";
}});
''')

    # 12.2 character counter
    (d / "counter.html").write_text(page(t, t["ch_title"], '''      label { display: block; font-weight: 700; margin-bottom: 6px; }
      textarea { width: 100%; max-width: 30em; height: 6em; font: inherit; padding: 10px; border: 2px solid #c7d2fe; border-radius: 10px; }
      #left { font-weight: 700; color: #059669; }
      #left.low { color: #dc2626; }
''', f'''    <h1>{t["ch_h1"]}</h1>
    <label for="message">{t["ch_label"]}</label>
    <textarea id="message" maxlength="120"></textarea>
    <p><span id="left">120</span> {t["ch_left"]}</p>''', "counter.js"))
    (d / "counter.js").write_text('''const message = document.querySelector("#message");
const left = document.querySelector("#left");
const limit = 120;

message.addEventListener("input", () => {
  const remaining = limit - message.value.length;
  left.textContent = remaining;
  left.classList.toggle("low", remaining < 20);
});
''')

    # 12.3 quiz
    qs = ",\n".join(
        f'  {{ text: "{q}", options: [{", ".join(chr(34) + o + chr(34) for o in opts)}], answer: {a} }}'
        for q, opts, a in t["questions"])
    (d / "quiz.html").write_text(page(t, t["qz_title"], '''      .card { max-width: 30em; background: white; border-radius: 16px; padding: 20px; box-shadow: 0 4px 14px rgb(67 56 202 / 0.12); }
      #options { display: flex; flex-direction: column; gap: 8px; margin: 14px 0; }
      #options button { background: #e0e7ff; color: #312e81; text-align: start; border-radius: 10px; }
      #feedback { min-height: 1.5em; font-weight: 700; }
      #feedback.right { color: #059669; }
      #feedback.wrong { color: #dc2626; }
''', f'''    <h1>{t["qz_h1"]}</h1>
    <div class="card">
      <p id="number"></p>
      <h2 id="question"></h2>
      <div id="options"></div>
      <p id="feedback"></p>
    </div>''', "quiz.js"))
    (d / "quiz.js").write_text(f'''const questions = [
{qs},
];

const number = document.querySelector("#number");
const question = document.querySelector("#question");
const options = document.querySelector("#options");
const feedback = document.querySelector("#feedback");

let current = 0;
let points = 0;

function show() {{
  const q = questions[current];
  number.textContent = `{t["qz_q"]} ${{current + 1}} {t["qz_of"]} ${{questions.length}}`;
  question.textContent = q.text;
  options.replaceChildren();

  q.options.forEach((option, index) => {{
    const button = document.createElement("button");
    button.textContent = option;
    button.addEventListener("click", () => choose(index));
    options.append(button);
  }});
}}

function choose(index) {{
  const q = questions[current];
  if (index === q.answer) {{
    points++;
    feedback.textContent = "{t["qz_right"]}";
    feedback.className = "right";
  }} else {{
    feedback.textContent = `{t["qz_wrong"]} ${{q.options[q.answer]}}{t["qz_end"]}`;
    feedback.className = "wrong";
  }}

  current++;
  if (current < questions.length) {{
    show();
  }} else {{
    finish();
  }}
}}

function finish() {{
  number.textContent = "";
  options.replaceChildren();
  question.textContent = `{t["qz_score"]} ${{points}} {t["qz_of"]} ${{questions.length}}`;

  const again = document.createElement("button");
  again.textContent = "{t["qz_again"]}";
  again.addEventListener("click", () => {{
    current = 0;
    points = 0;
    feedback.textContent = "";
    again.remove();
    show();
  }});
  options.append(again);
}}

show();
''')


for lang, t in T.items():
    write(lang, t)
print("ok")
