"""Writes the chapter 2 examples in English and Arabic. Run: python3 make.py"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "average.js": ('''// {c1}
const first = 8;
const second = 6;
const third = 10;

const total = first + second + third;
const average = total / 3;

console.log(`{msg}`);
''', {"en": {"c1": "Sequence: each step runs once, in order.", "msg": "Average: ${average}"},
      "ar": {"c1": "التسلسل: كل خطوة تُنفَّذ مرة واحدة بالترتيب.", "msg": "المتوسط: ${average}"}}),
    "largest.js": ('''const cards = [7, 3, 12, 5, 9];
let largest = cards[0];

for (const card of cards) {
  if (card > largest) {
    largest = card;
  }
}

console.log(`{msg}`);
''', {"en": {"msg": "The largest card is ${largest}"}, "ar": {"msg": "أكبر بطاقة هي ${largest}"}}),
    "halving.js": ('''let names = 1000000;
let steps = 0;

while (names > 1) {
  names = Math.ceil(names / 2);
  steps = steps + 1;
}

console.log(`{msg}`);
''', {"en": {"msg": "Steps needed: ${steps}"}, "ar": {"msg": "عدد الخطوات: ${steps}"}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        (HERE / lang).mkdir(exist_ok=True)
        (HERE / lang / name).write_text(s)
print("ok")
