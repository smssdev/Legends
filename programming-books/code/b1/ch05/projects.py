"""Writes the solutions of chapter 5's practice projects (HTML only), in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
import shutil
from pathlib import Path

HERE = Path(__file__).parent

T = {
    "en": dict(lang='lang="en"',
               r_title="Lentil Soup", r_h1="Grandma’s Lentil Soup", r_alt="A bowl of orange lentil soup with lemon",
               r_intro="A warm, simple soup ready in <strong>30 minutes</strong>. Serves four.",
               r_ing="Ingredients", r_items=["1 cup of red lentils", "1 onion, chopped", "1 carrot, chopped", "1 teaspoon of cumin", "5 cups of water", "Salt and lemon"],
               r_steps_h="Steps", r_steps=["Wash the lentils.", "Cook the onion and carrot in a little oil for 5 minutes.", "Add the lentils, cumin and water, and boil for 20 minutes.", "Blend until smooth, add salt, and serve with lemon."],
               c_title="Bean & Book Café", c_name="Bean &amp; Book Café", c_tag="Coffee, cake and a quiet corner to read.",
               c_nav=["Menu", "Opening hours", "Find us"], c_menu_h="Menu", c_menu=["Coffee: 30", "Tea with mint: 15", "Chocolate cake: 45"],
               c_hours_h="Opening hours", c_hours=["Saturday to Thursday: 8:00 to 22:00", "Friday: 14:00 to 23:00"],
               c_find_h="Find us", c_find="12 Library Street, Alexandria. Call us on <a href=\"tel:+201000000000\">010 0000 0000</a>.",
               c_foot="© 2026 Bean &amp; Book Café",
               f_title="Course sign-up", f_h1="Join the web course", f_name="Full name", f_email="Email", f_phone="Phone",
               f_level="Your level", f_levels=["Complete beginner", "I know some HTML", "I know HTML and CSS"],
               f_why="Why do you want to learn?", f_agree="I agree to receive emails about the course", f_btn="Sign me up"),
    "ar": dict(lang='lang="ar" dir="rtl"',
               r_title="شوربة العدس", r_h1="شوربة العدس على طريقة جدتي", r_alt="طبق من شوربة العدس البرتقالية مع الليمون",
               r_intro="شوربة دافئة بسيطة تجهز في <strong>30 دقيقة</strong>، وتكفي أربعة أشخاص.",
               r_ing="المكونات", r_items=["كوب عدس أصفر", "بصلة مقطعة", "جزرة مقطعة", "ملعقة صغيرة كمون", "5 أكواب ماء", "ملح وليمون"],
               r_steps_h="الخطوات", r_steps=["اغسل العدس.", "شوّح البصل والجزر في قليل من الزيت 5 دقائق.", "أضف العدس والكمون والماء، واتركه يغلي 20 دقيقة.", "اضربه في الخلاط حتى ينعم، وأضف الملح، وقدّمه مع الليمون."],
               c_title="مقهى البن والكتاب", c_name="مقهى البن والكتاب", c_tag="قهوة وكعك وركن هادئ للقراءة.",
               c_nav=["القائمة", "مواعيد العمل", "العنوان"], c_menu_h="القائمة", c_menu=["قهوة: 30", "شاي بالنعناع: 15", "كعكة الشوكولاتة: 45"],
               c_hours_h="مواعيد العمل", c_hours=["من السبت إلى الخميس: من 8:00 إلى 22:00", "الجمعة: من 14:00 إلى 23:00"],
               c_find_h="العنوان", c_find="12 شارع المكتبة، الإسكندرية. اتصل بنا على <a href=\"tel:+201000000000\">010 0000 0000</a>.",
               c_foot="© 2026 مقهى البن والكتاب",
               f_title="التسجيل في الدورة", f_h1="انضم إلى دورة الويب", f_name="الاسم الكامل", f_email="البريد الإلكتروني", f_phone="الهاتف",
               f_level="مستواك", f_levels=["مبتدئ تماماً", "أعرف بعض HTML", "أعرف HTML وCSS"],
               f_why="لماذا تريد أن تتعلم؟", f_agree="أوافق على استلام رسائل عن الدورة", f_btn="سجّلني"),
}


def head(lang, title):
    return f'''<!doctype html>
<html {lang}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{title}</title>
  </head>'''


def files(t):
    li = lambda xs, ind: "\n".join(f"{ind}<li>{x}</li>" for x in xs)
    nav = " |\n".join(f'        <a href="#{a}">{x}</a>' for a, x in zip(["menu", "hours", "find"], t["c_nav"]))
    opts = "\n".join(f'        <option>{x}</option>' for x in t["f_levels"])
    return {
        "recipe.html": f'''{head(t["lang"], t["r_title"])}
  <body>
    <h1>{t["r_h1"]}</h1>
    <img src="soup.svg" alt="{t["r_alt"]}" width="160" height="120">
    <p>{t["r_intro"]}</p>

    <h2>{t["r_ing"]}</h2>
    <ul>
{li(t["r_items"], "      ")}
    </ul>

    <h2>{t["r_steps_h"]}</h2>
    <ol>
{li(t["r_steps"], "      ")}
    </ol>
  </body>
</html>
''',
        "cafe.html": f'''{head(t["lang"], t["c_title"])}
  <body>
    <header>
      <h1>{t["c_name"]}</h1>
      <p>{t["c_tag"]}</p>
      <nav>
{nav}
      </nav>
    </header>

    <main>
      <section id="menu">
        <h2>{t["c_menu_h"]}</h2>
        <ul>
{li(t["c_menu"], "          ")}
        </ul>
      </section>
      <section id="hours">
        <h2>{t["c_hours_h"]}</h2>
        <ul>
{li(t["c_hours"], "          ")}
        </ul>
      </section>
      <section id="find">
        <h2>{t["c_find_h"]}</h2>
        <p>{t["c_find"]}</p>
      </section>
    </main>

    <footer>
      <p>{t["c_foot"]}</p>
    </footer>
  </body>
</html>
''',
        "signup.html": f'''{head(t["lang"], t["f_title"])}
  <body>
    <h1>{t["f_h1"]}</h1>
    <form>
      <p>
        <label for="name">{t["f_name"]}</label><br>
        <input id="name" type="text" required>
      </p>
      <p>
        <label for="email">{t["f_email"]}</label><br>
        <input id="email" type="email" required>
      </p>
      <p>
        <label for="phone">{t["f_phone"]}</label><br>
        <input id="phone" type="tel">
      </p>
      <p>
        <label for="level">{t["f_level"]}</label><br>
        <select id="level">
{opts}
        </select>
      </p>
      <p>
        <label for="why">{t["f_why"]}</label><br>
        <textarea id="why" rows="3" cols="40"></textarea>
      </p>
      <p>
        <input id="agree" type="checkbox">
        <label for="agree">{t["f_agree"]}</label>
      </p>
      <button type="submit">{t["f_btn"]}</button>
    </form>
  </body>
</html>
''',
    }


SOUP = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 120">
  <ellipse cx="80" cy="100" rx="70" ry="12" fill="#e5e7eb"/>
  <path d="M15,55 Q80,130 145,55 Z" fill="#fff" stroke="#1e1b2e" stroke-width="4" stroke-linejoin="round"/>
  <ellipse cx="80" cy="55" rx="65" ry="14" fill="#f59e0b" stroke="#1e1b2e" stroke-width="4"/>
  <circle cx="110" cy="52" r="9" fill="#facc15" stroke="#1e1b2e" stroke-width="3"/>
  <path d="M60,30 Q55,20 62,10 M80,30 Q75,18 82,6 M100,30 Q95,20 102,10" fill="none" stroke="#9ca3af" stroke-width="3" stroke-linecap="round"/>
</svg>
'''

for lang, t in T.items():
    d = HERE / lang / "projects"
    d.mkdir(parents=True, exist_ok=True)
    for name, text in files(t).items():
        (d / name).write_text(text)
    (d / "soup.svg").write_text(SOUP)
print("ok")
