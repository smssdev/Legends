import { createServer } from "node:http";
import { setTimeout as sleep } from "node:timers/promises";
import { extract, flush, inject, tracer } from "./tracer.ts";

const { start, span, end } = tracer("api");

createServer(async (request, response) => {
  const root = start(
    `${request.method} ${request.url}`,
    extract(request.headers.traceparent),
  );
  await span("db SELECT slot", root, () => sleep(6));
  const charge = await span("call payments", root, async (s) => {
    const answer = await fetch("http://localhost:4001/charges", {
      method: "POST",
      headers: inject(s),
    });
    return answer.json();
  });
  await span("db INSERT booking", root, () => sleep(4));
  await span("queue booking.created", root, () => sleep(1));
  end(root);
  response.end(JSON.stringify({ booking: 812, ...charge }));
  await flush();
}).listen(4000);
