"""Writes the solutions of chapter 9's practice projects, in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "class-stats.js": ('''const scores = [72, 95, 48, 83, 61, 90, 55, 77];

let total = 0;
let highest = scores[0];
let lowest = scores[0];
let passed = 0;

for (const score of scores) {
  total += score;
  if (score > highest) highest = score;
  if (score < lowest) lowest = score;
  if (score >= 50) passed++;
}

console.log("{students}", scores.length);
console.log("{avg}", total / scores.length);
console.log("{hi}", highest);
console.log("{lo}", lowest);
console.log("{pass}", passed, "/", scores.length);
''', {"en": {"students": "Students:", "avg": "Average:", "hi": "Highest:", "lo": "Lowest:", "pass": "Passed:"},
      "ar": {"students": "عدد الطلاب:", "avg": "المتوسط:", "hi": "الأعلى:", "lo": "الأدنى:", "pass": "الناجحون:"}}),
    "shopping-list.js": ('''const list = ["{a}", "{b}"];

const toAdd = ["{c}", "{a}", "{d}"];
for (const item of toAdd) {
  if (list.includes(item)) {
    console.log(`{dup}`);
  } else {
    list.push(item);
  }
}

console.log("{title}");
for (let i = 0; i < list.length; i++) {
  console.log(`${i + 1}. ${list[i]}`);
}
''', {"en": {"a": "bread", "b": "milk", "c": "eggs", "d": "tomatoes", "dup": "${item} is already on the list", "title": "Shopping list:"},
      "ar": {"a": "خبز", "b": "حليب", "c": "بيض", "d": "طماطم", "dup": "${item} موجود في القائمة أصلاً", "title": "قائمة التسوق:"}}),
    "patterns.js": ('''// {c1}
for (let n = 1; n <= 15; n++) {
  if (n % 3 === 0 && n % 5 === 0) {
    console.log("Bit Bot");
  } else if (n % 3 === 0) {
    console.log("Bit");
  } else if (n % 5 === 0) {
    console.log("Bot");
  } else {
    console.log(n);
  }
}

// {c2}
for (let row = 1; row <= 4; row++) {
  let line = "";
  for (let i = 0; i < row; i++) {
    line += "* ";
  }
  console.log(line);
}
''', {"en": {"c1": "1. The counting game: Bit for multiples of 3, Bot for 5, Bit Bot for both",
             "c2": "2. A triangle of stars: a loop inside a loop"},
      "ar": {"c1": "1. لعبة العد: Bit لمضاعفات 3، وBot لـ 5، وBit Bot للاثنين",
             "c2": "2. مثلث من النجوم: حلقة داخل حلقة"}}),
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
