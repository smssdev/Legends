import { createServer } from "node:http";

const work = Number(process.env.WORK_MS ?? 10);
const port = Number(process.env.PORT ?? 3000);

// 10 ms of work on the CPU: one request at a time, as a single Node.js process does
function busy(ms: number) {
  const end = performance.now() + ms;
  while (performance.now() < end);
}

createServer((_request, response) => {
  busy(work);
  response.end("ok");
}).listen(port);
