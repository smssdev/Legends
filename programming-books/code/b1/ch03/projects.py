"""Writes the solutions of chapter 3's practice projects, in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "folders.sh": ('''$ cd code-from-zero
$ mkdir book-notes
$ cd book-notes
$ mkdir part-1 part-2 part-3 part-4
$ ls
part-1    part-2    part-3    part-4
$ cd part-1
$ pwd
/Users/sara/code-from-zero/book-notes/part-1
$ cd ..
$ cd ..
$ pwd
/Users/sara/code-from-zero
''', {"en": {}, "ar": {}}),
    "quote.js": ('''// {c1}
const quotes = [
  "{q1}",
  "{q2}",
  "{q3}",
  "{q4}",
];

const today = 2;

console.log("{title}");
console.log(quotes[today]);
console.log("{count}", quotes.length);
''', {"en": {"c1": "A different quote for each day: change today from 0 to 3",
             "q1": "First, solve the problem. Then, write the code.",
             "q2": "Every expert was once a beginner.",
             "q3": "Small steps every day beat big steps once a month.",
             "q4": "Read the error message. All of it.",
             "title": "Quote of the day:", "count": "Quotes in the list:"},
      "ar": {"c1": "اقتباس مختلف لكل يوم: غيّر today من 0 إلى 3",
             "q1": "حُلّ المشكلة أولاً، ثم اكتب الكود.",
             "q2": "كل خبير كان يوماً مبتدئاً.",
             "q3": "خطوات صغيرة كل يوم خير من خطوة كبيرة كل شهر.",
             "q4": "اقرأ رسالة الخطأ. كلها.",
             "title": "اقتباس اليوم:", "count": "عدد الاقتباسات:"}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        d = HERE / lang / "projects"
        d.mkdir(parents=True, exist_ok=True)
        (d / name).write_text(s)
print("ok")
