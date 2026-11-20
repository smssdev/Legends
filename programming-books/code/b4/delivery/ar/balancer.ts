import { Agent, createServer, request } from "node:http";

const agent = new Agent({ keepAlive: true });
let pool = process.argv.slice(2).map(Number);
let next = 0;

createServer((incoming, outgoing) => {
  const url = new URL(incoming.url ?? "/", "http://x");
  // أداة النشر تضيف النسخ وتحذفها؛ والموزّع لا يُعاد تشغيله أبداً
  if (url.pathname === "/admin/pool") {
    pool = (url.searchParams.get("ports") ?? "")
      .split(",")
      .filter(Boolean)
      .map(Number);
    return outgoing.end(pool.join(","));
  }
  const port = pool[next++ % pool.length];
  const upstream = request(
    { host: "127.0.0.1", port, path: incoming.url, agent },
    (answer) => {
      outgoing.writeHead(answer.statusCode ?? 502);
      answer.pipe(outgoing);
    },
  );
  upstream.on("error", () => outgoing.writeHead(502).end());
  upstream.end();
}).listen(3000);
