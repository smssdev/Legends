import http from "node:http";

// A fake hosted API for the book: twice 'too many requests', then an
// answer.
export function fakeHostedApi() {
  let calls = 0;
  const server = http.createServer((request, response) => {
    calls++;
    let body = "";
    request.on("data", (chunk) => (body += chunk));
    request.on("end", () => {
      if (request.headers.authorization !== "Bearer test-key") {
        response.writeHead(401).end();
      } else if (calls <= 2) {
        response.writeHead(429).end();
      } else {
        const {messages} = JSON.parse(body);
        const content = `(fake model) you asked: ${messages.at(-1).content}`;
        response.writeHead(200, {"content-type": "application/json"});
        response.end(JSON.stringify({choices: [{message: {content}}]}));
      }
    });
  });
  return new Promise((resolve) => server.listen(0, () => resolve({server, port: server.address().port})));
}
