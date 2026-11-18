"""Writes the chapter 10 examples (functions) in English and Arabic. Run: python3 make.py"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "greet.js": ('''function greet(name) {
  return `{hello}`;
}

const message = greet("{sara}");
console.log(message);
console.log(greet("{omar}"));
''', {"en": {"hello": "Hello, ${name}!", "sara": "Sara", "omar": "Omar"},
      "ar": {"hello": "أهلاً يا ${name}!", "sara": "سارة", "omar": "عمر"}}),
    "price.js": ('''function ticketPrice(age) {
  if (age < 4) {
    return 0;
  }
  if (age < 13 || age >= 65) {
    return 6;
  }
  return 10;
}

console.log(ticketPrice(2));
console.log(ticketPrice(9));
console.log(ticketPrice(34));
console.log(ticketPrice(70));
''', {"en": {}, "ar": {}}),
    "params.js": ('''function area(width, height) {
  return width * height;
}

function welcome(name, language = "{lang}") {
  if (language === "ar") {
    return `مرحباً يا ${name}`;
  }
  return `Welcome, ${name}`;
}

console.log(area(4, 5));
console.log(welcome("{lina}"));
console.log(welcome("{lina}", "{other}"));
''', {"en": {"lang": "en", "lina": "Lina", "other": "ar"},
      "ar": {"lang": "ar", "lina": "لينا", "other": "en"}}),
    "scope.js": ('''const tax = 0.14;

function withTax(price) {
  const total = price + price * tax;
  return total;
}

console.log(withTax(100));
console.log(typeof total);
''', {"en": {}, "ar": {}}),
    "arrow.js": ('''const double = (n) => n * 2;
console.log(double(21));

const prices = [12, 5, 30, 8];

const withVat = prices.map((p) => p * 1.1);
console.log(withVat);

const cheap = prices.filter((p) => p < 10);
console.log(cheap);

const total = prices.reduce((sum, p) => sum + p, 0);
console.log(total);
''', {"en": {}, "ar": {}}),
    "kiosk.js": ('''// {c1}
function ticketPrice(age) {
  if (age < 4) return 0;
  if (age < 13 || age >= 65) return 6;
  return 10;
}

function applyMemberDay(price, isMember, day) {
  if (isMember && day === "{tue}") {
    return price / 2;
  }
  return price;
}

function receiptLine(visitor) {
  const base = ticketPrice(visitor.age);
  const price = applyMemberDay(base, visitor.member, "{tue}");
  return `{line}`;
}

// {c2}
const visitors = [
  { name: "{n1}", age: 34, member: true },
  { name: "{n2}", age: 9, member: false },
  { name: "{n3}", age: 70, member: true },
];

for (const visitor of visitors) {
  console.log(receiptLine(visitor));
}
''', {"en": {"c1": "Small functions, each with one job", "tue": "Tuesday", "line": "${visitor.name}: ${price}",
             "c2": "Each visitor is an object; you will learn objects in Chapter 11.", "n1": "Sara", "n2": "Adam", "n3": "Huda"},
      "ar": {"c1": "دوال صغيرة، لكل واحدة وظيفة واحدة", "tue": "الثلاثاء", "line": "${visitor.name}: ${price}",
             "c2": "كل زائر كائن، وستتعلم الكائنات في الفصل 11.", "n1": "سارة", "n2": "آدم", "n3": "هدى"}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        (HERE / lang).mkdir(exist_ok=True)
        (HERE / lang / name).write_text(s)
print("ok")
