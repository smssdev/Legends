const http = require("node:http");

// One small website with three pages, and a 404 page for everything else
const pages = {
  "/": "<h1>Home</h1>",
  "/about": "<h1>About us</h1>",
  "/contact": "<h1>Contact</h1>",
};

const server = http.createServer((request, response) => {
  const page = pages[request.url];
  if (page) {
    response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    response.end(page);
  } else {
    response.writeHead(404, { "Content-Type": "text/html; charset=utf-8" });
    response.end("<h1>Page not found</h1>");
  }
});

server.listen(3002, async () => {
  for (const path of ["/", "/about", "/contact", "/secret"]) {
    const reply = await fetch(`http://localhost:3002${path}`);
    console.log(path, reply.status, await reply.text());
  }
  server.close();
});
