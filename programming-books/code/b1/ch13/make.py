"""Writes the chapter 13 examples (asynchronous JavaScript and fetch) in English and Arabic.
Run: python3 make.py

fetch.js starts a small local API server and fetches from it, so it runs during the book build
without the internet. The shop page loads products.json, which the build serves over http.
"""
import json
from pathlib import Path

HERE = Path(__file__).parent
CH12 = HERE.parent / "ch12"

T = {
    "en": dict(start="Order placed", later="Food delivered!", end="Reading a book while waiting",
               boil="Boiling the water…", steep="Steeping the tea…", ready="Done.", tea="A cup of tea",
               meanwhile="Meanwhile, I set the table.", failed="Could not load:",
               loading="Loading products…", error="Sorry, the products could not be loaded. Please try again.",
               p=[("Code from Zero", 25), ("Bit mug", 8), ("Bit sticker", 3), ("Bit T-shirt", 15), ("Bit cap", 12)]),
    "ar": dict(start="تم الطلب", later="وصل الطعام!", end="أقرأ كتاباً وأنا أنتظر",
               boil="أغلي الماء…", steep="أنقع الشاي…", ready="انتهيت.", tea="كوب من الشاي",
               meanwhile="في الأثناء، أجهّز المائدة.", failed="تعذّر التحميل:",
               loading="جارٍ تحميل المنتجات…", error="عذراً، تعذّر تحميل المنتجات. حاول مرة أخرى.",
               p=[("البرمجة من الصفر", 25), ("كوب بِت", 8), ("ملصق بِت", 3), ("قميص بِت", 15), ("قبعة بِت", 12)]),
}


def files(t, lang):
    en = lang == "en"
    products = [{"id": i + 1, "name": n, "price": pr} for i, (n, pr) in enumerate(t["p"])]
    js_products = ",\n".join(f'  {{ id: {p["id"]}, name: "{p["name"]}", price: {p["price"]} }}' for p in products[:3])
    out = {
        "timers.js": f'''console.log("1. {t["start"]}");

setTimeout(() => {{
  console.log("3. {t["later"]}");
}}, 1000);

console.log("2. {t["end"]}");
''',
        "promise.js": f'''function wait(ms) {{
  return new Promise((resolve) => setTimeout(resolve, ms));
}}

async function makeTea() {{
  console.log("{t["boil"]}");
  await wait(300);
  console.log("{t["steep"]}");
  await wait(300);
  console.log("{t["ready"]}");
  return "{t["tea"]}";
}}

makeTea().then((result) => console.log(result));
console.log("{t["meanwhile"]}");
''',
        "fetch.js": f'''const http = require("node:http");

// {"A tiny API server with one address, /api/products" if en else "خادم واجهة برمجية صغير له عنوان واحد: /api/products"}
const products = [
{js_products},
];
const server = http.createServer((request, response) => {{
  if (request.url === "/api/products") {{
    response.writeHead(200, {{ "Content-Type": "application/json" }});
    response.end(JSON.stringify(products));
  }} else {{
    response.writeHead(404);
    response.end();
  }}
}});

// {"The client code: this is what runs in a real app" if en else "كود العميل: هذا ما يعمل في التطبيق الحقيقي"}
async function getJson(url) {{
  const response = await fetch(url);
  if (!response.ok) {{
    throw new Error(`HTTP ${{response.status}}`);
  }}
  return response.json();
}}

server.listen(3001, async () => {{
  const list = await getJson("http://localhost:3001/api/products");
  console.log(list.length, list[0].name);

  try {{
    await getJson("http://localhost:3001/api/missing");
  }} catch (error) {{
    console.log("{t["failed"]}", error.message);
  }}

  server.close();
}});
''',
        "products.json": json.dumps(products, ensure_ascii=False, indent=2) + "\n",
    }
    # The chapter 12 shop, now loading its products from products.json.
    shop_js = (CH12 / lang / "shop.js").read_text()
    start = shop_js.index("const catalog = [")
    end = shop_js.index("];", start) + 3
    shop_js = shop_js[:start] + "let catalog = [];\n" + shop_js[end:]
    shop_js = shop_js.replace("""renderProducts();
renderCart();
""", f"""// {"Load the products from the server, then draw the page" if en else "حمّل المنتجات من الخادم، ثم ارسم الصفحة"}
async function start() {{
  const status = document.querySelector("#status");
  status.textContent = "{t["loading"]}";
  try {{
    const response = await fetch("products.json");
    if (!response.ok) {{
      throw new Error(`HTTP ${{response.status}}`);
    }}
    catalog = await response.json();
    status.textContent = "";
    renderProducts();
    renderCart();
  }} catch (error) {{
    status.textContent = "{t["error"]}";
    console.error(error);
  }}
}}

start();
""")
    out["shop.js"] = shop_js
    out["shop.html"] = (CH12 / lang / "shop.html").read_text().replace(
        '      <section id="products"></section>',
        '      <section>\n        <p id="status" role="status"></p>\n        <div id="products"></div>\n      </section>')
    out["shop.css"] = (CH12 / lang / "shop.css").read_text() + "#status { font-weight: 700; color: #4338ca; margin: 0 0 8px; }\n#status:empty { display: none; }\n"
    return out


for lang, t in T.items():
    d = HERE / lang
    d.mkdir(exist_ok=True)
    for name, text in files(t, lang).items():
        (d / name).write_text(text)
print("ok")
