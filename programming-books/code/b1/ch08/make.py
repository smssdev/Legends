"""Writes the chapter 8 examples in English and Arabic from one template each.

The code is the same in both books; only the strings and comments change.
Run: python3 make.py (from this folder).
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "values.js": ('''console.log(42);
console.log(3.5);
console.log("{hello}");
console.log(true);

console.log(typeof 42);
console.log(typeof "{hello}");
console.log(typeof true);
''', {"en": {"hello": "Hello"}, "ar": {"hello": "مرحباً"}}),
    "variables.js": ('''let score = 0;
console.log(score);

score = score + 10;
console.log(score);

const name = "{sara}";
console.log("{player}", name);
''', {"en": {"sara": "Sara", "player": "Player:"}, "ar": {"sara": "سارة", "player": "اللاعبة:"}}),
    "const-error.js": ('''const maxPlayers = 4;
maxPlayers = 5;
''', {"en": {}, "ar": {}}),
    "operators.js": ('''const price = 12;
const count = 3;

console.log(price * count);
console.log(10 / 4);
console.log(10 % 4);

const first = "{first}";
const last = "{last}";
console.log(first + " " + last);
console.log(`{total}`);

console.log(5 === 5);
console.log(5 === "5");
console.log(5 == "5");
''', {"en": {"first": "Sara", "last": "Khan", "total": "Total: ${price * count} dollars"},
      "ar": {"first": "سارة", "last": "خان", "total": "المجموع: ${price * count} دولاراً"}}),
    "ticket.js": ('''const age = 9;
let price;

if (age < 4) {
  price = 0;
} else if (age < 13) {
  price = 6;
} else if (age >= 65) {
  price = 7;
} else {
  price = 10;
}

console.log(`{msg}`);
''', {"en": {"msg": "Age ${age}: $${price}"}, "ar": {"msg": "العمر ${age}: السعر ${price}$"}}),
    "logic.js": ('''const isMember = true;
const day = "{tue}";

if (isMember && day === "{tue}") {
  console.log("{half}");
}

const hasTicket = false;
if (!hasTicket) {
  console.log("{buy}");
}

const nickname = "";
const shown = nickname || "{guest}";
console.log(shown);
''', {"en": {"tue": "Tuesday", "half": "Half price today!", "buy": "Please buy a ticket.", "guest": "Guest"},
      "ar": {"tue": "الثلاثاء", "half": "نصف السعر اليوم!", "buy": "من فضلك اشترِ تذكرة.", "guest": "ضيف"}}),
    "switch.js": ('''const size = "M";
let drink;

switch (size) {
  case "S":
    drink = 2;
    break;
  case "M":
    drink = 3;
    break;
  case "L":
    drink = 4;
    break;
  default:
    drink = 0;
}

console.log(`{msg}`);
''', {"en": {"msg": "Drink: $${drink}"}, "ar": {"msg": "المشروب: ${drink}$"}}),
    "kiosk.js": ('''// {c1}
const age = 34;
const isMember = true;
const day = "{tue}";
const showTime = 22; // {c2}

let price;
if (age < 4) {
  price = 0;
} else if (age < 13 || age >= 65) {
  price = 6;
} else {
  price = 10;
}

if (isMember && day === "{tue}") {
  price = price / 2;
}

if (showTime >= 22 && price > 0) {
  price = price - 1;
}

const message = price === 0 ? "{free}" : `{pay}`;
console.log(message);
''', {"en": {"c1": "Ticket kiosk: change these values and run again.", "c2": "24-hour clock",
             "tue": "Tuesday", "free": "Free entry", "pay": "Please pay $${price}"},
      "ar": {"c1": "شبّاك التذاكر: غيّر هذه القيم وشغّل البرنامج من جديد.", "c2": "بنظام 24 ساعة",
             "tue": "الثلاثاء", "free": "الدخول مجاني", "pay": "ادفع ${price}$ من فضلك"}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        (HERE / lang).mkdir(exist_ok=True)
        (HERE / lang / name).write_text(s)
print("ok")
