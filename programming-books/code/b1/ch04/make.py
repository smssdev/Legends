"""Writes the chapter 4 examples in English and Arabic. Run: python3 make.py

server.js starts a real web server, asks it for a page with fetch, prints the reply and stops,
so it can run during the book build. request.txt and response.txt are shown, not run.
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "url.js": ('''const address = new URL(
  "https://shop.example.com:8080/products/shoes?size=42&color=red#reviews"
);

console.log(address.protocol);
console.log(address.hostname);
console.log(address.port);
console.log(address.pathname);
console.log(address.searchParams.get("size"));
console.log(address.hash);
''', {"en": {}, "ar": {}}),
    "server.js": ('''const http = require("node:http");

// {c1}
const server = http.createServer((request, response) => {
  console.log(`{got}`);
  response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  response.end("<h1>{hello}</h1>");
});

server.listen(3000, async () => {
  console.log("{listening}");

  // {c2}
  const reply = await fetch("http://localhost:3000/hello");
  console.log(reply.status, reply.statusText);
  console.log(reply.headers.get("content-type"));
  console.log(await reply.text());

  server.close();
});
''', {"en": {"c1": "The server: answers every request with a small HTML page.",
             "got": "Request: ${request.method} ${request.url}",
             "hello": "Hello from my server!",
             "listening": "Server ready at http://localhost:3000",
             "c2": "The client: ask our own server for a page, like a browser would."},
      "ar": {"c1": "الخادم: يجيب كل طلب بصفحة HTML صغيرة.",
             "got": "طلب: ${request.method} ${request.url}",
             "hello": "مرحباً من خادمي!",
             "listening": "الخادم جاهز على http://localhost:3000",
             "c2": "العميل: نطلب صفحة من خادمنا نفسه كما يفعل المتصفح."}}),
    "request.txt": ('''GET /products/shoes?size=42 HTTP/1.1
Host: shop.example.com
User-Agent: Mozilla/5.0 (Windows NT 10.0) Chrome/131
Accept: text/html
Accept-Language: {lang}
''', {"en": {"lang": "en-US,en"}, "ar": {"lang": "ar,en"}}),
    "response.txt": ('''HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 5120
Cache-Control: max-age=600

<!doctype html>
<html lang="{lang}">
  <head><title>{title}</title></head>
  ...
''', {"en": {"lang": "en", "title": "Shoes"}, "ar": {"lang": "ar", "title": "أحذية"}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        (HERE / lang).mkdir(exist_ok=True)
        (HERE / lang / name).write_text(s)
print("ok")
