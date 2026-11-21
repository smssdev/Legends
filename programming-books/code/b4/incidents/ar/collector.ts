import { createServer } from "node:http";
import type { Span } from "./tracer.ts";

// المجمّع الحقيقي (OpenTelemetry) يأخذ عينات ويخزن ويفهرس؛ وهذا يحتفظ بها فقط
const spans: Span[] = [];

createServer(async (request, response) => {
  if (request.method === "POST") {
    let body = "";
    for await (const chunk of request) body += chunk;
    spans.push(...(JSON.parse(body) as Span[]));
    return response.writeHead(204).end();
  }
  const traceId = request.url?.split("/").pop();
  response.end(JSON.stringify(spans.filter((s) => s.traceId === traceId)));
}).listen(4318);
