"""Writes the chapter 5 web pages in English and Arabic. Run: python3 make.py

The pages use no CSS at all: this chapter shows HTML exactly as the browser draws it by default.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[2]))
from decor import bit  # noqa: E402  Bit is the picture in the image examples

T = {
    "en": dict(
        lang='lang="en"', title1="My First Page", h1="Hello, web!",
        p1="This is my very first web page. I wrote it myself, in HTML.",
        t_title="Cairo Travel Notes", t_h1="Three Days in Cairo",
        t_p1='Cairo is <strong>huge, loud and wonderful</strong>. I spent three days there and still saw only a <em>tiny</em> part of it.',
        t_h2a="Day 1: The pyramids", t_p2="We arrived at Giza early, before the crowds. The Great Pyramid is even bigger than I imagined.",
        t_h2b="Day 2: Old Cairo", t_h3="Lunch", t_p3="We ate koshari, a dish of rice, lentils, pasta and a spicy tomato sauce.",
        l_title="Useful Links", l_h1="Places to learn",
        l_p1='The best reference for HTML is <a href="https://developer.mozilla.org">MDN Web Docs</a>.',
        l_p2='Go back to <a href="first.html">my first page</a>.',
        l_p3='Open <a href="https://developer.mozilla.org/en-US/docs/Web/HTML" target="_blank" rel="noopener">the HTML guide</a> in a new tab.',
        i_title="Meet Bit", i_h1="Meet Bit", i_alt="Bit, a small purple robot, waving",
        i_p="Bit is the friendly robot who guides you through this book.",
        s_title="Lists", s_h1="Making tea", s_h2a="You need", s_items=["Water", "Tea leaves", "A cup", "Sugar (optional)"],
        s_h2b="Steps", s_steps=["Boil the water.", "Put the tea in the cup.", "Pour the water and wait three minutes.", "Add sugar if you like."],
        st_title="Bit’s Blog", st_site="Bit’s Blog", st_nav=["Home", "Articles", "About"],
        st_h2="Why robots love HTML", st_p="Because every element has a clear job, and robots love clear jobs.",
        st_foot="© 2026 Bit. Made with HTML.",
        f_title="Newsletter", f_h1="Join the newsletter", f_name="Your name", f_email="Your email", f_btn="Sign me up",
        p_title="About Sara", p_name="Sara Khan", p_tag="Beginner web developer from Alexandria",
        p_nav=["About", "Skills", "Contact"], p_h2a="About me",
        p_about="I started learning to code this year with <em>Code from Zero</em>. I love building small tools that make life easier.",
        p_h2b="Skills I am learning", p_skills=["HTML", "CSS", "JavaScript"],
        p_h2c="Contact", p_contact='Write to me at <a href="mailto:sara@example.com">sara@example.com</a>.',
        p_alt="Sara’s avatar: a smiling purple robot", p_foot="Built by Sara, with HTML only.",
    ),
    "ar": dict(
        lang='lang="ar" dir="rtl"', title1="صفحتي الأولى", h1="مرحباً يا ويب!",
        p1="هذه أول صفحة ويب لي، كتبتها بنفسي بلغة HTML.",
        t_title="مذكرات رحلة القاهرة", t_h1="ثلاثة أيام في القاهرة",
        t_p1='القاهرة <strong>ضخمة وصاخبة ورائعة</strong>. قضيت فيها ثلاثة أيام ولم أرَ إلا جزءاً <em>صغيراً جداً</em> منها.',
        t_h2a="اليوم الأول: الأهرامات", t_p2="وصلنا إلى الجيزة مبكراً قبل الزحام. الهرم الأكبر أضخم مما تخيلت.",
        t_h2b="اليوم الثاني: القاهرة القديمة", t_h3="الغداء", t_p3="أكلنا الكشري: أرز وعدس ومكرونة وصلصة طماطم حارة.",
        l_title="روابط مفيدة", l_h1="أماكن للتعلم",
        l_p1='أفضل مرجع لـ HTML هو <a href="https://developer.mozilla.org">MDN Web Docs</a>.',
        l_p2='ارجع إلى <a href="first.html">صفحتي الأولى</a>.',
        l_p3='افتح <a href="https://developer.mozilla.org/ar/docs/Web/HTML" target="_blank" rel="noopener">دليل HTML</a> في تبويب جديد.',
        i_title="تعرّف على بِت", i_h1="تعرّف على بِت", i_alt="بِت، روبوت بنفسجي صغير يلوّح بيده",
        i_p="بِت هو الروبوت اللطيف الذي يرافقك في هذا الكتاب.",
        s_title="القوائم", s_h1="إعداد الشاي", s_h2a="تحتاج إلى", s_items=["ماء", "شاي", "كوب", "سكر (اختياري)"],
        s_h2b="الخطوات", s_steps=["اغلِ الماء.", "ضع الشاي في الكوب.", "صبّ الماء وانتظر ثلاث دقائق.", "أضف السكر إن أحببت."],
        st_title="مدونة بِت", st_site="مدونة بِت", st_nav=["الرئيسية", "المقالات", "من أنا"],
        st_h2="لماذا تحب الروبوتات HTML", st_p="لأن لكل عنصر وظيفة واضحة، والروبوتات تحب الوظائف الواضحة.",
        st_foot="© 2026 بِت. صُنعت بـ HTML.",
        f_title="النشرة البريدية", f_h1="اشترك في النشرة", f_name="اسمك", f_email="بريدك الإلكتروني", f_btn="اشترك",
        p_title="عن سارة", p_name="سارة خان", p_tag="مطورة ويب مبتدئة من الإسكندرية",
        p_nav=["عني", "مهاراتي", "تواصل"], p_h2a="عني",
        p_about="بدأت تعلم البرمجة هذا العام مع كتاب <em>البرمجة من الصفر</em>، وأحب بناء أدوات صغيرة تجعل الحياة أسهل.",
        p_h2b="مهارات أتعلمها", p_skills=["HTML", "CSS", "JavaScript"],
        p_h2c="تواصل معي", p_contact='راسلني على <a href="mailto:sara@example.com">sara@example.com</a>.',
        p_alt="صورة سارة الرمزية: روبوت بنفسجي مبتسم", p_foot="بنتها سارة بـ HTML وحدها.",
    ),
}


def head(lang, title):
    return f'''<!doctype html>
<html {lang}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{title}</title>
  </head>'''


def pages(t):
    lis = lambda xs, ind: "\n".join(f"{ind}<li>{x}</li>" for x in xs)
    nav = lambda xs, ind: "\n".join(f'{ind}<li><a href="#">{x}</a></li>' for x in xs)
    return {
        "first.html": f'''{head(t["lang"], t["title1"])}
  <body>
    <h1>{t["h1"]}</h1>
    <p>{t["p1"]}</p>
  </body>
</html>
''',
        "text.html": f'''{head(t["lang"], t["t_title"])}
  <body>
    <h1>{t["t_h1"]}</h1>
    <p>{t["t_p1"]}</p>

    <h2>{t["t_h2a"]}</h2>
    <p>{t["t_p2"]}</p>

    <h2>{t["t_h2b"]}</h2>
    <h3>{t["t_h3"]}</h3>
    <p>{t["t_p3"]}</p>
  </body>
</html>
''',
        "links.html": f'''{head(t["lang"], t["l_title"])}
  <body>
    <h1>{t["l_h1"]}</h1>
    <p>{t["l_p1"]}</p>
    <p>{t["l_p2"]}</p>
    <p>{t["l_p3"]}</p>
  </body>
</html>
''',
        "image.html": f'''{head(t["lang"], t["i_title"])}
  <body>
    <h1>{t["i_h1"]}</h1>
    <img src="bit.svg" alt="{t["i_alt"]}" width="120" height="140">
    <p>{t["i_p"]}</p>
  </body>
</html>
''',
        "lists.html": f'''{head(t["lang"], t["s_title"])}
  <body>
    <h1>{t["s_h1"]}</h1>

    <h2>{t["s_h2a"]}</h2>
    <ul>
{lis(t["s_items"], "      ")}
    </ul>

    <h2>{t["s_h2b"]}</h2>
    <ol>
{lis(t["s_steps"], "      ")}
    </ol>
  </body>
</html>
''',
        "structure.html": f'''{head(t["lang"], t["st_title"])}
  <body>
    <header>
      <h1>{t["st_site"]}</h1>
      <nav>
        <ul>
{nav(t["st_nav"], "          ")}
        </ul>
      </nav>
    </header>

    <main>
      <article>
        <h2>{t["st_h2"]}</h2>
        <p>{t["st_p"]}</p>
      </article>
    </main>

    <footer>
      <p>{t["st_foot"]}</p>
    </footer>
  </body>
</html>
''',
        "form.html": f'''{head(t["lang"], t["f_title"])}
  <body>
    <h1>{t["f_h1"]}</h1>
    <form>
      <p>
        <label for="name">{t["f_name"]}</label>
        <input id="name" name="name" type="text" required>
      </p>
      <p>
        <label for="email">{t["f_email"]}</label>
        <input id="email" name="email" type="email" required>
      </p>
      <button type="submit">{t["f_btn"]}</button>
    </form>
  </body>
</html>
''',
        "profile.html": f'''{head(t["lang"], t["p_title"])}
  <body>
    <header>
      <img src="bit.svg" alt="{t["p_alt"]}" width="90" height="105">
      <h1>{t["p_name"]}</h1>
      <p>{t["p_tag"]}</p>
      <nav>
        <a href="#about">{t["p_nav"][0]}</a> |
        <a href="#skills">{t["p_nav"][1]}</a> |
        <a href="#contact">{t["p_nav"][2]}</a>
      </nav>
    </header>

    <main>
      <section id="about">
        <h2>{t["p_h2a"]}</h2>
        <p>{t["p_about"]}</p>
      </section>

      <section id="skills">
        <h2>{t["p_h2b"]}</h2>
        <ul>
{lis(t["p_skills"], "          ")}
        </ul>
      </section>

      <section id="contact">
        <h2>{t["p_h2c"]}</h2>
        <p>{t["p_contact"]}</p>
      </section>
    </main>

    <footer>
      <p>{t["p_foot"]}</p>
    </footer>
  </body>
</html>
''',
    }


svg = bit("happy").replace('<svg viewBox', '<svg xmlns="http://www.w3.org/2000/svg" viewBox').replace(' aria-hidden="true"', '')
for lang, t in T.items():
    d = HERE / lang
    d.mkdir(exist_ok=True)
    for name, text in pages(t).items():
        (d / name).write_text(text)
    (d / "bit.svg").write_text(svg + "\n")
print("ok")
