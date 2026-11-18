"""Writes the chapter 9 examples (loops and arrays) in English and Arabic. Run: python3 make.py"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "arrays.js": ('''const fruits = ["{f1}", "{f2}", "{f3}"];

console.log(fruits);
console.log(fruits.length);
console.log(fruits[0]);
console.log(fruits[fruits.length - 1]);

fruits.push("{f4}");
console.log(fruits);

console.log(fruits.includes("{f2}"));
console.log(fruits.indexOf("{f3}"));
''', {"en": {"f1": "apple", "f2": "banana", "f3": "mango", "f4": "orange"},
      "ar": {"f1": "تفاح", "f2": "موز", "f3": "مانجو", "f4": "برتقال"}}),
    "for.js": ('''for (let i = 1; i <= 5; i++) {
  console.log(`{step}`);
}

// {c1}
for (let n = 3; n > 0; n--) {
  console.log(n);
}
console.log("{go}");
''', {"en": {"step": "Step ${i}", "c1": "Counting down", "go": "Go!"},
      "ar": {"step": "الخطوة ${i}", "c1": "العد التنازلي", "go": "انطلق!"}}),
    "for-of.js": ('''const prices = [12, 5, 30, 8];
let total = 0;

for (const price of prices) {
  total = total + price;
}

console.log(`{items}`);
console.log(`{total}`);
console.log(`{avg}`);
''', {"en": {"items": "Items: ${prices.length}", "total": "Total: ${total}", "avg": "Average: ${total / prices.length}"},
      "ar": {"items": "عدد الأصناف: ${prices.length}", "total": "المجموع: ${total}", "avg": "المتوسط: ${total / prices.length}"}}),
    "while.js": ('''let savings = 0;
let week = 0;
const goal = 100;

while (savings < goal) {
  week++;
  savings = savings + 15;
}

console.log(`{msg}`);
''', {"en": {"msg": "Reached ${savings} after ${week} weeks"},
      "ar": {"msg": "وصلت إلى ${savings} بعد ${week} أسابيع"}}),
    "break.js": ('''const scores = [72, 85, -1, 90, 64];

for (const score of scores) {
  if (score < 0) {
    console.log("{bad}");
    break;
  }
  if (score < 75) {
    continue;
  }
  console.log(`{good}`);
}
''', {"en": {"bad": "Invalid score, stopping.", "good": "Great score: ${score}"},
      "ar": {"bad": "درجة غير صحيحة، توقفنا.", "good": "درجة ممتازة: ${score}"}}),
    "queue.js": ('''// {c1}
const queue = [34, 9, 2, 70, 16, 41, 3];

let total = 0;
let freeTickets = 0;
const receipt = [];

for (const age of queue) {
  let price;
  if (age < 4) {
    price = 0;
    freeTickets++;
  } else if (age < 13 || age >= 65) {
    price = 6;
  } else {
    price = 10;
  }
  total = total + price;
  receipt.push(price);
}

console.log(`{served}`);
console.log(`{prices}`);
console.log(`{free}`);
console.log(`{sum}`);
''', {"en": {"c1": "Ages of the visitors waiting in line", "served": "Visitors served: ${queue.length}",
             "prices": 'Prices: ${receipt.join(", ")}', "free": "Free tickets: ${freeTickets}", "sum": "Total: ${total}"},
      "ar": {"c1": "أعمار الزوار في الطابور", "served": "عدد الزوار: ${queue.length}",
             "prices": 'الأسعار: ${receipt.join("، ")}', "free": "تذاكر مجانية: ${freeTickets}", "sum": "المجموع: ${total}"}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        (HERE / lang).mkdir(exist_ok=True)
        (HERE / lang / name).write_text(s)
print("ok")
