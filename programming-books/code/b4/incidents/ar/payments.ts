import { createServer } from "node:http";
import { setTimeout as sleep } from "node:timers/promises";
import { extract, flush, tracer } from "./tracer.ts";

const { start, span, end } = tracer("payments");
// SLOW=1: يستغرق مزوّد الدفع نحو ثانية
const providerMs = process.env.SLOW ? 1000 : 40;

createServer(async (request, response) => {
  const root = start(
    `${request.method} ${request.url}`,
    extract(request.headers.traceparent),
  );
  await span("fraud check", root, () => sleep(10));
  await span("provider checkout", root, () => sleep(providerMs));
  end(root);
  response.end(JSON.stringify({ checkout: "cs_812" }));
  await flush();
}).listen(4001);
