"""Writes the chapter 14 examples (reading errors and debugging) in English and Arabic.
Run: python3 make.py
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "reference.js": ('''const score = 10;
console.log(scor);
''', {"en": {}, "ar": {}}),
    "type.js": ('''const user = undefined;
console.log(user.name);
''', {"en": {}, "ar": {}}),
    "syntax.js": ('''const prices = [10, 20, 30;
console.log(prices);
''', {"en": {}, "ar": {}}),
    "stack.js": ('''function getCity(user) {
  return user.address.city;
}

function welcome(user) {
  return `{hi}`;
}

console.log(welcome({ name: "{sara}" }));
''', {"en": {"hi": "Hello from ${getCity(user)}!", "sara": "Sara"},
      "ar": {"hi": "أهلاً من ${getCity(user)}!", "sara": "سارة"}}),
    "average-bug.js": ('''// {c1}
function average(numbers) {
  let total = 0;
  for (let i = 1; i < numbers.length; i++) {
    total = total + numbers[i];
  }
  return total / numbers.length;
}

console.log(average([10, 20, 30]));
''', {"en": {"c1": "The average of 10, 20 and 30 should be 20…"},
      "ar": {"c1": "متوسط 10 و20 و30 يجب أن يكون 20…"}}),
    "average-trace.js": ('''function average(numbers) {
  let total = 0;
  for (let i = 1; i < numbers.length; i++) {
    console.log("i =", i, "number =", numbers[i], "total =", total);
    total = total + numbers[i];
  }
  console.log("{final}", total);
  return total / numbers.length;
}

console.log(average([10, 20, 30]));
''', {"en": {"final": "final total:"}, "ar": {"final": "المجموع النهائي:"}}),
    "average-fixed.js": ('''function average(numbers) {
  let total = 0;
  for (const number of numbers) {
    total = total + number;
  }
  return total / numbers.length;
}

console.log(average([10, 20, 30]));
console.log(average([7]));
''', {"en": {}, "ar": {}}),
    "console.js": ('''const cart = [
  { name: "{p1}", price: 25, quantity: 1 },
  { name: "{p2}", price: 3, quantity: 2 },
];

console.log("{label}", cart.length);
console.table(cart);
console.error("{err}");
''', {"en": {"p1": "Book", "p2": "Sticker", "label": "Items in cart:", "err": "Something is wrong here!"},
      "ar": {"p1": "Book", "p2": "Sticker", "label": "عدد العناصر في السلة:", "err": "هناك خطأ هنا!"}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        (HERE / lang).mkdir(exist_ok=True)
        (HERE / lang / name).write_text(s)
print("ok")
