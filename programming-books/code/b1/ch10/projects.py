"""Writes the solutions of chapter 10's practice projects, in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "converter.js": ('''function kmToMiles(km) {
  return km * 0.621371;
}

function kgToPounds(kg) {
  return kg * 2.20462;
}

function celsiusToFahrenheit(c) {
  return (c * 9) / 5 + 32;
}

function round(value, digits = 1) {
  return Number(value.toFixed(digits));
}

console.log("10 km =", round(kmToMiles(10)), "{mi}");
console.log("70 kg =", round(kgToPounds(70)), "{lb}");
console.log("37 °C =", round(celsiusToFahrenheit(37)), "°F");
console.log("42.195 km =", round(kmToMiles(42.195), 2), "{mi}");
''', {"en": {"mi": "miles", "lb": "pounds"}, "ar": {"mi": "ميلاً", "lb": "رطلاً"}}),
    "password.js": ('''function hasDigit(text) {
  for (const char of text) {
    if ("0123456789".includes(char)) return true;
  }
  return false;
}

function hasUpper(text) {
  return text !== text.toLowerCase();
}

function strength(password) {
  let points = 0;
  if (password.length >= 8) points++;
  if (password.length >= 12) points++;
  if (hasDigit(password)) points++;
  if (hasUpper(password)) points++;

  if (points <= 1) return "{weak}";
  if (points <= 3) return "{ok}";
  return "{strong}";
}

for (const password of ["cat", "sunshine", "sunshine2026", "Sunshine2026Blue"]) {
  console.log(password, "→", strength(password));
}
''', {"en": {"weak": "weak", "ok": "okay", "strong": "strong"}, "ar": {"weak": "ضعيفة", "ok": "مقبولة", "strong": "قوية"}}),
    "sales.js": ('''const orders = [
  { product: "{p1}", quantity: 2, price: 25 },
  { product: "{p2}", quantity: 5, price: 3 },
  { product: "{p3}", quantity: 1, price: 8 },
  { product: "{p1}", quantity: 1, price: 25 },
  { product: "{p2}", quantity: 10, price: 3 },
];

const lineTotal = (order) => order.quantity * order.price;

const revenue = orders.map(lineTotal).reduce((sum, value) => sum + value, 0);
const bigOrders = orders.filter((order) => lineTotal(order) >= 25);
const stickersSold = orders
  .filter((order) => order.product === "{p2}")
  .reduce((sum, order) => sum + order.quantity, 0);

console.log("{rev}", revenue);
console.log("{big}", bigOrders.length);
console.log("{st}", stickersSold);
''', {"en": {"p1": "book", "p2": "sticker", "p3": "mug", "rev": "Revenue:", "big": "Orders of 25 or more:", "st": "Stickers sold:"},
      "ar": {"p1": "كتاب", "p2": "ملصق", "p3": "كوب", "rev": "الإيرادات:", "big": "طلبات بقيمة 25 أو أكثر:", "st": "الملصقات المبيعة:"}}),
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
