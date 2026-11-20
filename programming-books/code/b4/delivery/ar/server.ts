import { createServer } from "node:http";
import { setTimeout as sleep } from "node:timers/promises";

const version = process.env.VERSION ?? "v1";
let ready = false;
let stopping = false;

const server = createServer(async (request, response) => {
  // جاهز فقط حين يستطيع الخدمة؛ والموزّع يسأل قبل أن يرسل الحركة
  if (request.url === "/ready") return response.writeHead(ready ? 200 : 503).end();
  // أثناء التوقف، قل للعملاء ألا يعيدوا استعمال الاتصال، وإلا أبقوه حياً إلى الأبد
  if (stopping) response.setHeader("connection", "close");
  await sleep(20);
  response.end(version);
});
server.listen(Number(process.env.PORT));

// الخادم الحقيقي يحتاج وقتاً ليبدأ: اتصالات، وذاكرات مؤقتة، وكود يُترجم
await sleep(1000);
ready = true;

// SIGTERM: توقف عن القبول، وأنهِ ما يجري، ثم اخرج
process.on("SIGTERM", () => {
  ready = false;
  stopping = true;
  server.close(() => process.exit(0));
  server.closeIdleConnections();
});
