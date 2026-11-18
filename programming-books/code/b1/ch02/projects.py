"""Writes the solutions of chapter 2's practice projects, in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "cheapest.js": ('''const prices = [42, 18, 35, 9, 27];
let cheapest = prices[0];

for (const price of prices) {
  if (price < cheapest) {
    cheapest = price;
  }
}

console.log(`{msg}`);
''', {"en": {"msg": "The cheapest price is ${cheapest}"}, "ar": {"msg": "أرخص سعر هو ${cheapest}"}}),
    "guess.js": ('''const secret = 73;
let low = 1;
let high = 100;
let tries = 0;

while (true) {
  const guess = Math.floor((low + high) / 2);
  tries++;
  if (guess === secret) {
    console.log(`{found}`);
    break;
  }
  if (guess < secret) {
    console.log(`{higher}`);
    low = guess + 1;
  } else {
    console.log(`{lower}`);
    high = guess - 1;
  }
}
''', {"en": {"found": "Guess ${tries}: ${guess}. Got it!", "higher": "Guess ${tries}: ${guess}, too low",
             "lower": "Guess ${tries}: ${guess}, too high"},
      "ar": {"found": "المحاولة ${tries}: ${guess}. وجدته!", "higher": "المحاولة ${tries}: ${guess}، أصغر من الرقم",
             "lower": "المحاولة ${tries}: ${guess}، أكبر من الرقم"}}),
    "sort-three.js": ('''let a = 12;
let b = 3;
let c = 7;

// {c1}
if (a > b) [a, b] = [b, a];
if (b > c) [b, c] = [c, b];
if (a > b) [a, b] = [b, a];

console.log(a, b, c);
''', {"en": {"c1": "Three comparisons are enough to sort three numbers"},
      "ar": {"c1": "ثلاث مقارنات تكفي لترتيب ثلاثة أرقام"}}),
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
