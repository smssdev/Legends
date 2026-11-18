"""Writes the solutions of chapter 11's practice projects, in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "book-card.js": ('''const book = {
  title: "{t}",
  author: "{a}",
  pages: 312,
  read: false,
};

book.read = true;
book.rating = 5;

for (const [key, value] of Object.entries(book)) {
  console.log(key + ":", value);
}
console.log("{n}", Object.keys(book).length);
''', {"en": {"t": "The Little Prince", "a": "Antoine de Saint-Exupéry", "n": "Properties:"},
      "ar": {"t": "الأمير الصغير", "a": "أنطوان دو سانت إكزوبيري", "n": "عدد الخصائص:"}}),
    "grades.js": ('''const students = [
  { name: "{s1}", marks: [90, 85, 100] },
  { name: "{s2}", marks: [70, 65, 80] },
  { name: "{s3}", marks: [95, 92, 97] },
];

function average(marks) {
  const total = marks.reduce((sum, mark) => sum + mark, 0);
  return Math.round(total / marks.length);
}

let best = null;
for (const { name, marks } of students) {
  const avg = average(marks);
  console.log(name, "→", avg);
  if (best === null || avg > best.avg) best = { name, avg };
}
console.log("{top}", best.name, "(" + best.avg + ")");
''', {"en": {"s1": "Mona", "s2": "Omar", "s3": "Sara", "top": "Top of the class:"},
      "ar": {"s1": "منى", "s2": "عمر", "s3": "سارة", "top": "الأول على الفصل:"}}),
    "settings.js": ('''const defaults = { theme: "light", fontSize: 16, language: "{lang}" };

// {c1}
const saved = '{"theme":"dark","fontSize":18}';

const settings = { ...defaults, ...JSON.parse(saved) };
console.log(settings);

const updated = { ...settings, fontSize: settings.fontSize + 2 };
console.log("{old}", settings.fontSize, "{new}", updated.fontSize);

const text = JSON.stringify(updated, null, 2);
console.log(text);
''', {"en": {"lang": "en", "c1": "What the app stored last time, as JSON text", "old": "Before:", "new": "after:"},
      "ar": {"lang": "ar", "c1": "ما حفظه التطبيق في المرة الماضية، نصاً بصيغة JSON", "old": "قبل:", "new": "بعد:"}}),
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
