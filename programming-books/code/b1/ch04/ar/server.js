const http = require("node:http");

// الخادم: يجيب كل طلب بصفحة HTML صغيرة.
const server = http.createServer((request, response) => {
  console.log(`طلب: ${request.method} ${request.url}`);
  response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  response.end("<h1>مرحباً من خادمي!</h1>");
});

server.listen(3000, async () => {
  console.log("الخادم جاهز على http://localhost:3000");

  // العميل: نطلب صفحة من خادمنا نفسه كما يفعل المتصفح.
  const reply = await fetch("http://localhost:3000/hello");
  console.log(reply.status, reply.statusText);
  console.log(reply.headers.get("content-type"));
  console.log(await reply.text());

  server.close();
});
