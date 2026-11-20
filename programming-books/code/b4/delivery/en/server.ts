import { createServer } from "node:http";
import { setTimeout as sleep } from "node:timers/promises";

const version = process.env.VERSION ?? "v1";
let ready = false;
let stopping = false;

const server = createServer(async (request, response) => {
  // ready only when it can serve; the balancer asks before sending traffic
  if (request.url === "/ready") return response.writeHead(ready ? 200 : 503).end();
  // while stopping, tell clients not to reuse the connection, or they keep it alive forever
  if (stopping) response.setHeader("connection", "close");
  await sleep(20);
  response.end(version);
});
server.listen(Number(process.env.PORT));

// a real server needs time to start: connections, caches, compiled code
await sleep(1000);
ready = true;

// SIGTERM: stop accepting, finish what is in flight, then exit
process.on("SIGTERM", () => {
  ready = false;
  stopping = true;
  server.close(() => process.exit(0));
  server.closeIdleConnections();
});
