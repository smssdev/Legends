import { createServer, type ServerResponse } from "node:http";
import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import { Worker } from "node:worker_threads";
import { log } from "./log.ts";

function json(res: ServerResponse, status: number, body: unknown): void {
  const text = JSON.stringify(body);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(text),
  });
  res.end(text);
}

// خيط لكل طلب: بسيط، ومناسب للأعمال الثقيلة النادرة
function countInWorker(limit: number): Promise<number> {
  return new Promise((resolve, reject) => {
    const worker = new Worker(new URL("./primes-worker.ts", import.meta.url), {
      workerData: limit,
    });
    worker.once("message", resolve);
    worker.once("error", reject);
  });
}

// تُصنع الصفوف واحداً واحداً، حين يكون العميل مستعداً لها
async function* orderRows(count: number) {
  yield "id,customer,total\n";
  for (let id = 1; id <= count; id++) {
    yield `${id},customer-${id % 97},${(id * 7919) % 100000}\n`;
  }
}

export function createApp() {
  return createServer(async (req, res) => {
    const start = performance.now();
    res.on("finish", () => {
      const ms = Math.round(performance.now() - start);
      log("info", `${req.method} ${req.url} ${res.statusCode} ${ms}ms`);
    });
    try {
      const url = new URL(req.url ?? "/", "http://localhost");
      if (url.pathname === "/hello") {
        return json(res, 200, { message: "أهلاً من متجر Bit" });
      }
      if (url.pathname === "/primes") {
        const limit = Number(url.searchParams.get("limit"));
        if (!Number.isInteger(limit) || limit < 1 || limit > 10_000_000) {
          return json(res, 422, { error: { code: "invalid", message: "يجب أن يكون limit عدداً صحيحاً من 1 إلى 10000000" } });
        }
        const primes = await countInWorker(limit);
        return json(res, 200, { limit, primes, ms: Math.round(performance.now() - start) });
      }
      if (url.pathname === "/export") {
        res.writeHead(200, { "Content-Type": "text/csv; charset=utf-8" });
        return await pipeline(Readable.from(orderRows(100_000)), res);
      }
      json(res, 404, { error: { code: "not_found", message: "لا شيء هنا" } });
    } catch (error) {
      log("error", String(error));
      if (!res.headersSent) {
        json(res, 500, { error: { code: "server_error", message: "حدث خطأ عندنا" } });
      } else {
        res.destroy();
      }
    }
  });
}
