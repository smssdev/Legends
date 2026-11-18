"""Writes the solutions of chapter 8's practice projects, in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "grade.js": ('''const score = 83;
let grade;

if (score < 0 || score > 100) {
  grade = "{invalid}";
} else if (score >= 90) {
  grade = "A";
} else if (score >= 80) {
  grade = "B";
} else if (score >= 70) {
  grade = "C";
} else if (score >= 50) {
  grade = "D";
} else {
  grade = "F";
}

const passed = score >= 50 && score <= 100;
console.log(`{line}`);
console.log(passed ? "{pass}" : "{fail}");
''', {"en": {"invalid": "Invalid score", "line": "Score ${score}: grade ${grade}", "pass": "Passed. Well done!", "fail": "Not passed. Try again!"},
      "ar": {"invalid": "درجة غير صحيحة", "line": "الدرجة ${score}: التقدير ${grade}", "pass": "ناجح. أحسنت!", "fail": "لم تنجح. حاول مرة أخرى!"}}),
    "shipping.js": ('''const weight = 3.5; // kg
const express = true;
const city = "{alex}";
const orderTotal = 640;

let cost;
if (weight <= 1) {
  cost = 30;
} else if (weight <= 5) {
  cost = 50;
} else {
  cost = 50 + Math.ceil(weight - 5) * 10;
}

if (express) {
  cost = cost * 2;
}

if (city !== "{cairo}" && city !== "{alex}") {
  cost = cost + 20;
}

const free = orderTotal >= 1000 && !express;
console.log(`{w}`);
console.log(free ? "{freeMsg}" : `{costMsg}`);
''', {"en": {"alex": "Alexandria", "cairo": "Cairo", "w": "Weight: ${weight} kg, express: ${express}, city: ${city}",
             "freeMsg": "Shipping: free!", "costMsg": "Shipping: ${cost}"},
      "ar": {"alex": "الإسكندرية", "cairo": "القاهرة", "w": "الوزن: ${weight} كجم، سريع: ${express}، المدينة: ${city}",
             "freeMsg": "الشحن: مجاني!", "costMsg": "الشحن: ${cost}"}}),
    "calendar.js": ('''const year = 2028;
const month = 2;

// {c1}
const isLeap = (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;

let days;
switch (month) {
  case 2:
    days = isLeap ? 29 : 28;
    break;
  case 4:
  case 6:
  case 9:
  case 11:
    days = 30;
    break;
  default:
    days = 31;
}

console.log(`{leap}`);
console.log(`{days}`);
''', {"en": {"c1": "Leap years: every 4 years, except every 100, except every 400",
             "leap": "${year} is a leap year: ${isLeap}", "days": "Month ${month} of ${year} has ${days} days"},
      "ar": {"c1": "السنة الكبيسة: كل 4 سنوات، إلا كل 100، إلا كل 400",
             "leap": "هل ${year} سنة كبيسة؟ ${isLeap}", "days": "الشهر ${month} من ${year} فيه ${days} يوماً"}}),
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
