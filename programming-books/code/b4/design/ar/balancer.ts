import { Agent, createServer, request } from "node:http";

const ports = process.argv.slice(2).map(Number);
// أبقِ الاتصالات بالنسخ مفتوحة، كما تفعل موزّعات الحمل الحقيقية
const agent = new Agent({ keepAlive: true });
let next = 0;

createServer((incoming, outgoing) => {
  // التناوب الدائري: كل طلب إلى النسخة التالية، بالدور
  const port = ports[next++ % ports.length];
  const upstream = request(
    {
      host: "127.0.0.1",
      port,
      path: incoming.url,
      method: incoming.method,
      headers: incoming.headers,
      agent,
    },
    (answer) => {
      outgoing.writeHead(answer.statusCode ?? 502, answer.headers);
      answer.pipe(outgoing);
    },
  );
  upstream.on("error", () => outgoing.writeHead(502).end());
  incoming.pipe(upstream);
}).listen(3000);
