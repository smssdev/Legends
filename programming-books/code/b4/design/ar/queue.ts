import { createServer } from "node:http";

const work = Number(process.env.WORK_MS ?? 10);
const port = Number(process.env.PORT ?? 3000);

// 10 ms من العمل على المعالج: طلب واحد في كل مرة، كما تفعل عملية Node.js واحدة
function busy(ms: number) {
  const end = performance.now() + ms;
  while (performance.now() < end);
}

createServer((_request, response) => {
  busy(work);
  response.end("ok");
}).listen(port);
