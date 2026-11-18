"""Writes chapter 14's practice projects (bug hunts), in English and Arabic: each bug and its fix.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

GREET = '''const firstName = "{name}";
const visits = 3;

function welcome(person, count) {
  const message = `{hello} ${person}! {visit} #${count}`;
  return message;
}

console.log(welcome(firstname, visits));
'''

CART = '''// {c1}
const prices = ["120", "45", "35"];
const discount = 20;

function total(list) {
  let sum = 0;
  for (let i = 0; i <= list.length; i++) {
    sum = sum + list[i];
  }
  return sum;
}

const before = total(prices);
console.log("{before}", before);
console.log("{after}", before - discount);
'''

CART_FIXED = '''// {c1}
const prices = ["120", "45", "35"];
const discount = 20;

function total(list) {
  let sum = 0;
  for (let i = 0; i < list.length; i++) {
    sum = sum + Number(list[i]);
  }
  return sum;
}

const before = total(prices);
console.log("{before}", before);
console.log("{after}", before - discount);
'''

ORDERS = '''const orders = [
  { id: 1, customer: { name: "{n1}" }, total: 40 },
  { id: 2, total: 15 },
  { id: 3, customer: { name: "{n2}" }, total: 22 },
];

function label(order) {
  return `#${order.id} ${order.customer.name}: ${order.total}`;
}

function printAll(list) {
  for (const order of list) {
    console.log(label(order));
  }
}

printAll(orders);
'''

ORDERS_FIXED = ORDERS.replace('''function label(order) {
  return''', '''function label(order) {
  if (!order.customer) {
    return `#${order.id} {guest}: ${order.total}`;
  }
  return''')

FILES = {
    "greet-bug.js": GREET,
    "greet-fixed.js": GREET.replace("welcome(firstname,", "welcome(firstName,"),
    "cart-bug.js": CART,
    "cart-fixed.js": CART_FIXED,
    "orders-bug.js": ORDERS,
    "orders-fixed.js": ORDERS_FIXED,
}

LANGS = {
    "en": {"name": "Sara", "hello": "Welcome back,", "visit": "visit",
           "c1": "Prices arrive as text, as they do from a form or a file",
           "before": "Total:", "after": "After discount:",
           "n1": "Omar", "n2": "Huda", "guest": "(guest)"},
    "ar": {"name": "سارة", "hello": "مرحباً بعودتك يا", "visit": "زيارتك",
           "c1": "الأسعار تصل نصوصاً، كما تصل من نموذج أو ملف",
           "before": "المجموع:", "after": "بعد الخصم:",
           "n1": "عمر", "n2": "هدى", "guest": "(زائر)"},
}

for name, tpl in FILES.items():
    for lang, vals in LANGS.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        d = HERE / lang / "projects"
        d.mkdir(parents=True, exist_ok=True)
        (d / name).write_text(s)
print("ok")
