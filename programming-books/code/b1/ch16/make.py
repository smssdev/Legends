"""Writes the chapter 16 examples (accessibility) in English and Arabic. Run: python3 make.py"""
from pathlib import Path

HERE = Path(__file__).parent

T = {
    "en": dict(lang='lang="en"', title="Accessible buttons", h1="Two buttons", bad="I am a div", good="I am a button",
               note="Both look the same. Only one works with a keyboard and a screen reader.",
               f_title="Sign up", f_h1="Create an account", f_email="Email", f_hint="We never share your email.",
               f_pass="Password", f_btn="Create account", f_err="Please enter a valid email address.",
               c_good="Good contrast", c_bad="Poor contrast", c_ratio="ratio",
               skip="Skip to main content", menu=["Home", "Projects", "Contact"],
               main_h="Welcome", main_p="Press Tab to move between links. The focused link has a clear outline.",
               fg="foreground", bg="background"),
    "ar": dict(lang='lang="ar" dir="rtl"', title="أزرار يصل إليها الجميع", h1="زرّان", bad="أنا div", good="أنا زر",
               note="يبدوان متشابهين، لكن واحداً منهما فقط يعمل بلوحة المفاتيح وقارئ الشاشة.",
               f_title="التسجيل", f_h1="أنشئ حساباً", f_email="البريد الإلكتروني", f_hint="لن نشارك بريدك مع أحد أبداً.",
               f_pass="كلمة المرور", f_btn="أنشئ الحساب", f_err="من فضلك اكتب بريداً إلكترونياً صحيحاً.",
               c_good="تباين جيد", c_bad="تباين ضعيف", c_ratio="النسبة",
               skip="تخطَّ إلى المحتوى الرئيسي", menu=["الرئيسية", "المشاريع", "تواصل"],
               main_h="أهلاً بك", main_p="اضغط Tab للتنقل بين الروابط، والرابط المحدد عليه إطار واضح.",
               fg="النص", bg="الخلفية"),
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


def files(t, lang):
    en = lang == "en"
    out = {}
    out["buttons.html"] = f'''{head(t["lang"], t["title"], """      body { font-family: system-ui, sans-serif; margin: 24px; }
      .fake, button { display: inline-block; padding: 10px 20px; border: 0; border-radius: 999px;
        color: white; background: #4338ca; font: inherit; cursor: pointer; margin: 4px; }
""")}
  <body>
    <h1>{t["h1"]}</h1>
    <!-- {"Bad: looks like a button, but is only a box" if en else "سيئ: يبدو زراً لكنه صندوق فقط"} -->
    <div class="fake" onclick="alert('Hi')">{t["bad"]}</div>
    <!-- {"Good: a real button" if en else "جيد: زر حقيقي"} -->
    <button type="button" onclick="alert('Hi')">{t["good"]}</button>
    <p>{t["note"]}</p>
  </body>
</html>
'''
    out["form.html"] = f'''{head(t["lang"], t["f_title"], """      body { font-family: system-ui, sans-serif; margin: 24px; max-width: 420px; }
      label { display: block; font-weight: 700; margin-top: 14px; }
      input { display: block; width: 100%; box-sizing: border-box; padding: 8px; font: inherit;
        border: 2px solid #5b5873; border-radius: 8px; }
      input[aria-invalid="true"] { border-color: #b91c1c; }
      .hint { color: #4a4760; margin: 4px 0 0; font-size: 0.9rem; }
      .error { color: #b91c1c; font-weight: 700; margin: 4px 0 0; }
      button { margin-top: 18px; padding: 10px 22px; border: 0; border-radius: 999px; color: white; background: #4338ca; font: inherit; }
""")}
  <body>
    <h1>{t["f_h1"]}</h1>
    <form novalidate>
      <label for="email">{t["f_email"]}</label>
      <input id="email" type="email" autocomplete="email"
             aria-describedby="email-hint email-error" aria-invalid="true" value="sara@">
      <p class="hint" id="email-hint">{t["f_hint"]}</p>
      <p class="error" id="email-error" role="alert">{t["f_err"]}</p>

      <label for="password">{t["f_pass"]}</label>
      <input id="password" type="password" autocomplete="new-password">

      <button type="submit">{t["f_btn"]}</button>
    </form>
  </body>
</html>
'''
    menu = "\n".join(f'        <a href="#">{m}</a>' for m in t["menu"])
    out["focus.html"] = f'''{head(t["lang"], t["main_h"], """      body { font-family: system-ui, sans-serif; margin: 0; }
      .skip { position: absolute; inset-inline-start: 8px; top: -60px; padding: 8px 14px;
        background: #1e1b2e; color: white; border-radius: 8px; }
      .skip:focus { top: 8px; }
      nav { display: flex; gap: 8px; padding: 56px 16px 16px; background: #eef2ff; }
      nav a { padding: 6px 14px; border-radius: 8px; color: #312e81; font-weight: 700; }
      a:focus-visible { outline: 3px solid #db2777; outline-offset: 3px; }
      main { padding: 0 16px; }
      @media (prefers-reduced-motion: reduce) {
        * { animation: none !important; transition: none !important; }
      }
""")}
  <body>
    <a class="skip" href="#main">{t["skip"]}</a>
    <header>
      <nav aria-label="{"Main" if en else "الرئيسية"}">
{menu}
      </nav>
    </header>
    <main id="main">
      <h1>{t["main_h"]}</h1>
      <p>{t["main_p"]}</p>
    </main>
  </body>
</html>
'''
    out["contrast.js"] = f'''// {"Contrast ratio between two colours, using the WCAG formula" if en else "نسبة التباين بين لونين بمعادلة WCAG"}
function luminance(hex) {{
  const channels = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);
  const linear = channels.map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2];
}}

function contrast(foreground, background) {{
  const [a, b] = [luminance(foreground), luminance(background)].sort((x, y) => y - x);
  return (a + 0.05) / (b + 0.05);
}}

const pairs = [
  ["#1e1b2e", "#ffffff"],
  ["#4338ca", "#ffffff"],
  ["#9ca3af", "#ffffff"],
  ["#ffffff", "#fbbf24"],
];

for (const [fg, bg] of pairs) {{
  const ratio = contrast(fg, bg);
  const verdict = ratio >= 4.5 ? "{"pass" if en else "ناجح"}" : "{"fail" if en else "راسب"}";
  console.log(`${{fg}} / ${{bg}}: ${{ratio.toFixed(2)}} → ${{verdict}}`);
}}
'''
    return out


for lang, t in T.items():
    d = HERE / lang
    d.mkdir(exist_ok=True)
    for name, text in files(t, lang).items():
        (d / name).write_text(text)
print("ok")
