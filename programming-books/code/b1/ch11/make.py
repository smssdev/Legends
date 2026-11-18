"""Writes the chapter 11 examples (objects and JSON) in English and Arabic. Run: python3 make.py"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "object.js": ('''const book = {
  title: "{title}",
  pages: 340,
  inStock: true,
  tags: ["{t1}", "{t2}"],
};

console.log(book.title);
console.log(book["pages"]);
console.log(book.tags[0]);

book.pages = 352;
book.price = 25;
console.log(book);
''', {"en": {"title": "Code from Zero", "t1": "beginners", "t2": "javascript"},
      "ar": {"title": "البرمجة من الصفر", "t1": "مبتدئين", "t2": "جافاسكربت"}}),
    "products.js": ('''const products = [
  { id: 1, name: "{p1}", price: 25, category: "{book}" },
  { id: 2, name: "{p2}", price: 8, category: "{mug}" },
  { id: 3, name: "{p3}", price: 30, category: "{book}" },
  { id: 4, name: "{p4}", price: 3, category: "{sticker}" },
];

const books = products.filter((p) => p.category === "{book}");
console.log(books.map((p) => p.name));

const found = products.find((p) => p.id === 2);
console.log(found.name, found.price);

const cheapest = products.reduce((a, b) => (b.price < a.price ? b : a));
console.log(cheapest.name);
''', {"en": {"p1": "Code from Zero", "p2": "Bit mug", "p3": "Senior Frontend", "p4": "Bit sticker",
             "book": "book", "mug": "mug", "sticker": "sticker"},
      "ar": {"p1": "البرمجة من الصفر", "p2": "كوب بِت", "p3": "هندسة الواجهات", "p4": "ملصق بِت",
             "book": "كتاب", "mug": "كوب", "sticker": "ملصق"}}),
    "destructure.js": ('''const visitor = { name: "{sara}", age: 34, city: "{alex}" };

const { name, city } = visitor;
console.log(`{msg}`);

const copy = { ...visitor, age: 35 };
console.log(visitor.age, copy.age);
''', {"en": {"sara": "Sara", "alex": "Alexandria", "msg": "${name} lives in ${city}"},
      "ar": {"sara": "سارة", "alex": "الإسكندرية", "msg": "${name} تسكن في ${city}"}}),
    "json.js": ('''const order = { id: 501, items: ["{i1}", "{i2}"], paid: false };

const text = JSON.stringify(order);
console.log(text);
console.log(typeof text);

const back = JSON.parse('{"id":502,"items":["{i3}"],"paid":true}');
console.log(back.items[0], back.paid);
''', {"en": {"i1": "book", "i2": "mug", "i3": "sticker"}, "ar": {"i1": "كتاب", "i2": "كوب", "i3": "ملصق"}}),
    "cart.js": ('''const catalog = [
  { id: 1, name: "{p1}", price: 25 },
  { id: 2, name: "{p2}", price: 8 },
  { id: 3, name: "{p3}", price: 3 },
];

const cart = [];

function addToCart(productId, quantity = 1) {
  const line = cart.find((item) => item.productId === productId);
  if (line) {
    line.quantity += quantity;
  } else {
    cart.push({ productId, quantity });
  }
}

function lineTotal(item) {
  const product = catalog.find((p) => p.id === item.productId);
  return product.price * item.quantity;
}

function cartTotal() {
  return cart.reduce((sum, item) => sum + lineTotal(item), 0);
}

addToCart(1);
addToCart(3, 4);
addToCart(1);

for (const item of cart) {
  const product = catalog.find((p) => p.id === item.productId);
  console.log(`${product.name} × ${item.quantity} = ${lineTotal(item)}`);
}
console.log(`{total}`);

// {c1}
console.log(JSON.stringify(cart));
''', {"en": {"p1": "Code from Zero", "p2": "Bit mug", "p3": "Bit sticker", "total": "Total: ${cartTotal()}",
             "c1": "Ready to save or send to a server"},
      "ar": {"p1": "البرمجة من الصفر", "p2": "كوب بِت", "p3": "ملصق بِت", "total": "المجموع: ${cartTotal()}",
             "c1": "جاهزة للحفظ أو الإرسال إلى خادم"}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        (HERE / lang).mkdir(exist_ok=True)
        (HERE / lang / name).write_text(s)
print("ok")
