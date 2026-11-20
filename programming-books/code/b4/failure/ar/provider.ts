import { createServer } from "node:http";
import { setTimeout as sleep } from "node:timers/promises";

// flaky: كل رابع طلب يفشل، وكل عاشر يستغرق 3 ثوانٍ؛ down: كل طلب يفشل
let mode = process.env.MODE ?? "flaky";
let seen = 0;

createServer(async (request, response) => {
  if (request.url === "/stats") return response.end(JSON.stringify({ seen }));
  if (request.url?.startsWith("/mode/")) {
    mode = request.url.slice(6);
    seen = 0;
    return response.end(mode);
  }
  const n = ++seen;
  if (mode === "down") {
    await sleep(20);
    return response.writeHead(503).end("down");
  }
  if (n % 10 === 0) await sleep(3000);
  if (n % 4 === 0) return response.writeHead(500).end("error");
  response.end(JSON.stringify({ checkout: `cs_${n}` }));
}).listen(4000);
