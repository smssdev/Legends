const http = require("node:http");

const menu = [
  { name: "Koshari", price: 45 },
  { name: "Falafel plate", price: 60 },
  { name: "Mint tea", price: 25 },
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
