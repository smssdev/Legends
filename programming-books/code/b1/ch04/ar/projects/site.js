const http = require("node:http");

// موقع صغير بثلاث صفحات، وصفحة 404 لكل ما سواها
const pages = {
  "/": "<h1>الرئيسية</h1>",
  "/about": "<h1>من نحن</h1>",
  "/contact": "<h1>تواصل معنا</h1>",
};

const server = http.createServer((request, response) => {
  const page = pages[request.url];
  if (page) {
    response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    response.end(page);
  } else {
    response.writeHead(404, { "Content-Type": "text/html; charset=utf-8" });
    response.end("<h1>الصفحة غير موجودة</h1>");
  }
});

server.listen(3002, async () => {
  for (const path of ["/", "/about", "/contact", "/secret"]) {
    const reply = await fetch(`http://localhost:3002${path}`);
    console.log(path, reply.status, await reply.text());
  }
  server.close();
});
