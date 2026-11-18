"""Writes the chapter 12 examples (DOM and events) in English and Arabic. Run: python3 make.py"""
from pathlib import Path

HERE = Path(__file__).parent

T = {
    "en": dict(lang='lang="en"', c_title="Counter", c_h1="Bit’s clicker", c_btn="Click me", c_reset="Reset",
               c_msg="You clicked ${count} times", c_start="You clicked 0 times",
               s_title="Changing a page", s_h1="Old title", s_new="New title, set by JavaScript!",
               s_p="This paragraph will be highlighted.", s_items=["HTML", "CSS"], s_add="JavaScript",
               f_title="Greeting", f_label="Your name", f_btn="Say hello", f_empty="Please type your name.",
               f_hello="Hello, ${name}! Welcome to the web.", f_fill="Sara",
               shop_title="Bit’s Shop", shop_h1="Bit’s Shop", cart="Your cart", empty="Your cart is empty.",
               add="Add to cart", total="Total", currency="$",
               p=[("Code from Zero", 25), ("Bit mug", 8), ("Bit sticker", 3), ("Bit T-shirt", 15)]),
    "ar": dict(lang='lang="ar" dir="rtl"', c_title="العدّاد", c_h1="عدّاد بِت", c_btn="اضغطني", c_reset="تصفير",
               c_msg="ضغطت ${count} مرات", c_start="ضغطت 0 مرات",
               s_title="تغيير الصفحة", s_h1="العنوان القديم", s_new="عنوان جديد كتبته JavaScript!",
               s_p="ستُميَّز هذه الفقرة.", s_items=["HTML", "CSS"], s_add="JavaScript",
               f_title="الترحيب", f_label="اسمك", f_btn="رحّب بي", f_empty="من فضلك اكتب اسمك.",
               f_hello="أهلاً يا ${name}! مرحباً بك في الويب.", f_fill="سارة",
               shop_title="متجر بِت", shop_h1="متجر بِت", cart="سلتك", empty="سلتك فارغة.",
               add="أضف إلى السلة", total="المجموع", currency="$",
               p=[("البرمجة من الصفر", 25), ("كوب بِت", 8), ("ملصق بِت", 3), ("قميص بِت", 15)]),
}

BASE_CSS = '''      body { font-family: system-ui, sans-serif; margin: 24px; }
      button { font: inherit; padding: 8px 18px; border: 0; border-radius: 999px; color: white; background: #4338ca; cursor: pointer; }
      button.secondary { background: #e0e7ff; color: #4338ca; }
      .highlight { background: #fef3c7; padding: 6px 10px; border-radius: 8px; }
      #output { font-size: 1.3rem; font-weight: 700; color: #db2777; }
'''


def head(lang, title, css=BASE_CSS, extra=""):
    return f'''<!doctype html>
<html {lang}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{title}</title>{extra}
    <style>
{css}    </style>
  </head>'''


def files(t):
    out = {}
    out["counter.html"] = f'''{head(t["lang"], t["c_title"])}
  <body>
    <h1>{t["c_h1"]}</h1>
    <p id="output">{t["c_start"]}</p>
    <button id="add">{t["c_btn"]}</button>
    <button id="reset" class="secondary">{t["c_reset"]}</button>
    <script src="counter.js"></script>
  </body>
</html>
'''
    out["counter.js"] = f'''const output = document.querySelector("#output");
const addButton = document.querySelector("#add");
const resetButton = document.querySelector("#reset");

let count = 0;

function show() {{
  output.textContent = `{t["c_msg"]}`;
}}

addButton.addEventListener("click", () => {{
  count++;
  show();
}});

resetButton.addEventListener("click", () => {{
  count = 0;
  show();
}});
'''
    items = "\n".join(f"      <li>{x}</li>" for x in t["s_items"])
    out["change.html"] = f'''{head(t["lang"], t["s_title"])}
  <body>
    <h1>{t["s_h1"]}</h1>
    <p class="note">{t["s_p"]}</p>
    <ul id="skills">
{items}
    </ul>
    <script src="change.js"></script>
  </body>
</html>
'''
    out["change.js"] = f'''// 1. {"Change text" if t["lang"].startswith('lang="en"') else "تغيير النص"}
const title = document.querySelector("h1");
title.textContent = "{t["s_new"]}";

// 2. {"Add a class (the CSS does the styling)" if t["lang"].startswith('lang="en"') else "إضافة صنف (وCSS تتولى التنسيق)"}
document.querySelector(".note").classList.add("highlight");

// 3. {"Create a new element and add it to the page" if t["lang"].startswith('lang="en"') else "إنشاء عنصر جديد وإضافته إلى الصفحة"}
const item = document.createElement("li");
item.textContent = "{t["s_add"]}";
document.querySelector("#skills").append(item);
'''
    out["greet.html"] = f'''{head(t["lang"], t["f_title"])}
  <body>
    <form id="greet">
      <label for="name">{t["f_label"]}</label>
      <input id="name" type="text">
      <button type="submit">{t["f_btn"]}</button>
    </form>
    <p id="output"></p>
    <script src="greet.js"></script>
  </body>
</html>
'''
    out["greet.js"] = f'''const form = document.querySelector("#greet");
const input = document.querySelector("#name");
const output = document.querySelector("#output");

form.addEventListener("submit", (event) => {{
  event.preventDefault();

  const name = input.value.trim();
  if (name === "") {{
    output.textContent = "{t["f_empty"]}";
    return;
  }}
  output.textContent = `{t["f_hello"]}`;
  input.value = "";
}});
'''
    products = ",\n".join(f'  {{ id: {i + 1}, name: "{n}", price: {pr} }}' for i, (n, pr) in enumerate(t["p"]))
    out["shop.html"] = f'''<!doctype html>
<html {t["lang"]}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{t["shop_title"]}</title>
    <link rel="stylesheet" href="shop.css">
  </head>
  <body>
    <header><h1>{t["shop_h1"]}</h1></header>
    <main>
      <section id="products"></section>
      <aside id="cart">
        <h2>{t["cart"]}</h2>
        <ul id="cart-lines"></ul>
        <p id="cart-total"></p>
      </aside>
    </main>
    <script src="shop.js"></script>
  </body>
</html>
'''
    out["shop.css"] = '''* { box-sizing: border-box; }
body { margin: 0; font-family: system-ui, sans-serif; background: #f5f5fb; color: #1e1b2e; }
header { padding: 16px 24px; color: white; background: #4338ca; }
header h1 { margin: 0; }
main { display: grid; grid-template-columns: 1fr 240px; gap: 16px; padding: 16px 24px; }
#products { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; align-content: start; }
.card { background: white; border-radius: 14px; padding: 14px; box-shadow: 0 2px 8px rgba(30, 27, 46, 0.08); }
.card h3 { margin: 0 0 4px; font-size: 1rem; }
.card p { margin: 0 0 10px; color: #db2777; font-weight: 700; }
.card button { width: 100%; padding: 8px; border: 0; border-radius: 999px; color: white; background: #4338ca; font: inherit; cursor: pointer; }
#cart { background: white; border-radius: 14px; padding: 4px 16px 12px; align-self: start; box-shadow: 0 2px 8px rgba(30, 27, 46, 0.08); }
#cart-lines { padding: 0; list-style: none; }
#cart-lines li { display: flex; justify-content: space-between; padding: 4px 0; border-bottom: 1px solid #eef2ff; }
#cart-total { font-weight: 700; font-size: 1.2rem; color: #4338ca; }
@media (max-width: 560px) { main { grid-template-columns: 1fr; } }
'''
    en = t["lang"].startswith('lang="en"')
    out["shop.js"] = f'''const catalog = [
{products},
];

const cart = [];

// {"Draw one card per product" if en else "ارسم بطاقة لكل منتج"}
function renderProducts() {{
  const container = document.querySelector("#products");
  for (const product of catalog) {{
    const card = document.createElement("article");
    card.className = "card";

    const name = document.createElement("h3");
    name.textContent = product.name;

    const price = document.createElement("p");
    price.textContent = `{t["currency"]}${{product.price}}`;

    const button = document.createElement("button");
    button.textContent = "{t["add"]}";
    button.addEventListener("click", () => addToCart(product.id));

    card.append(name, price, button);
    container.append(card);
  }}
}}

function addToCart(productId) {{
  const line = cart.find((item) => item.productId === productId);
  if (line) {{
    line.quantity++;
  }} else {{
    cart.push({{ productId, quantity: 1 }});
  }}
  renderCart();
}}

// {"Redraw the cart from the data every time it changes" if en else "أعد رسم السلة من البيانات كلما تغيرت"}
function renderCart() {{
  const list = document.querySelector("#cart-lines");
  list.replaceChildren();

  let total = 0;
  for (const item of cart) {{
    const product = catalog.find((p) => p.id === item.productId);
    const lineTotal = product.price * item.quantity;
    total += lineTotal;

    const li = document.createElement("li");
    li.textContent = `${{product.name}} × ${{item.quantity}}`;
    const amount = document.createElement("span");
    amount.textContent = `{t["currency"]}${{lineTotal}}`;
    li.append(amount);
    list.append(li);
  }}

  document.querySelector("#cart-total").textContent =
    cart.length === 0 ? "{t["empty"]}" : `{t["total"]}: {t["currency"]}${{total}}`;
}}

renderProducts();
renderCart();
'''
    return out


for lang, t in T.items():
    d = HERE / lang
    d.mkdir(exist_ok=True)
    for name, text in files(t).items():
        (d / name).write_text(text)
print("ok")
