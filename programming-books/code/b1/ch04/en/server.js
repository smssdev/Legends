const http = require("node:http");

// The server: answers every request with a small HTML page.
const server = http.createServer((request, response) => {
  console.log(`Request: ${request.method} ${request.url}`);
  response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  response.end("<h1>Hello from my server!</h1>");
});

server.listen(3000, async () => {
  console.log("Server ready at http://localhost:3000");

  // The client: ask our own server for a page, like a browser would.
  const reply = await fetch("http://localhost:3000/hello");
  console.log(reply.status, reply.statusText);
  console.log(reply.headers.get("content-type"));
  console.log(await reply.text());

  server.close();
});
