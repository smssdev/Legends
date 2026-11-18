"""Writes the solutions of chapter 4's practice projects, in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "inspect-urls.js": ('''const addresses = [
  "https://www.example.com/news/sport?team=ahly&page=2",
  "http://localhost:3000/about",
  "https://shop.example.com/cart#summary",
];

for (const text of addresses) {
  const url = new URL(text);
  console.log(url.hostname, "|", url.pathname, "|", url.search || "{none}", "|", url.hash || "{none}");
}
''', {"en": {"none": "-"}, "ar": {"none": "-"}}),
    "site.js": ('''const http = require("node:http");

// {c1}
const pages = {
  "/": "<h1>{home}</h1>",
  "/about": "<h1>{about}</h1>",
  "/contact": "<h1>{contact}</h1>",
};

const server = http.createServer((request, response) => {
  const page = pages[request.url];
  if (page) {
    response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    response.end(page);
  } else {
    response.writeHead(404, { "Content-Type": "text/html; charset=utf-8" });
    response.end("<h1>{missing}</h1>");
  }
});

server.listen(3002, async () => {
  for (const path of ["/", "/about", "/contact", "/secret"]) {
    const reply = await fetch(`http://localhost:3002${path}`);
    console.log(path, reply.status, await reply.text());
  }
  server.close();
});
''', {"en": {"c1": "One small website with three pages, and a 404 page for everything else",
             "home": "Home", "about": "About us", "contact": "Contact", "missing": "Page not found"},
      "ar": {"c1": "موقع صغير بثلاث صفحات، وصفحة 404 لكل ما سواها",
             "home": "الرئيسية", "about": "من نحن", "contact": "تواصل معنا", "missing": "الصفحة غير موجودة"}}),
    "menu-api.js": ('''const http = require("node:http");

const menu = [
  { name: "{d1}", price: 45 },
  { name: "{d2}", price: 60 },
  { name: "{d3}", price: 25 },
];

const server = http.createServer((request, response) => {
  if (request.url === "/api/menu") {
    response.writeHead(200, { "Content-Type": "application/json; charset=utf-8" });
    response.end(JSON.stringify(menu));
  } else {
    response.writeHead(404);
    response.end();
  }
});

server.listen(3003, async () => {
  const reply = await fetch("http://localhost:3003/api/menu");
  console.log(reply.status, reply.headers.get("content-type"));
  console.log(await reply.text());
  server.close();
});
''', {"en": {"d1": "Koshari", "d2": "Falafel plate", "d3": "Mint tea"},
      "ar": {"d1": "كشري", "d2": "طبق فلافل", "d3": "شاي بالنعناع"}}),
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
