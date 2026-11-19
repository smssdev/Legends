"""Writes the examples of Book 3 (Node.js edition), chapter 2 "Node.js and TypeScript on the Server".
Run: python3 make.py   (after `npm ci` in code/b3)

A small but real Node project per language (<lang>/): package.json, tsconfig.json, src/ with config,
app, server and a worker thread, tests, and demos/ for the event loop, concurrency and streams. Every
program is run for real; what the terminal showed is saved as the transcripts the chapter prints (*.sh).
"""
import os
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent.parent
sys.path.insert(0, str(B3))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_hello="Hello from Bit's shop", w_e_limit="limit must be a whole number from 1 to 10000000",
        w_e_none="Nothing here", w_e_500="Something went wrong on our side",
        w_listen="Listening on", w_stop="no new connections, finishing requests in progress",
        w_closed="all requests finished, bye", w_force="requests still running after 10 s, stopping anyway",
        w_crash="unexpected error, stopping", w_bad_config="Invalid configuration:",
        w_c_worker="Runs in its own thread, so a long count never blocks the event loop.",
        w_c_count="Counts the primes up to limit, the slow way: pure CPU work.",
        w_c_one="one thread per request: simple, and fine for rare heavy jobs",
        w_c_rows="rows are made one by one, when the client is ready for them",
        w_c_env="process.env holds strings only: coerce and check them once, at start-up",
        w_c_frozen="read-only: nothing can change the configuration later",
        w_c_stop="stop accepting, let running requests finish",
        w_c_idle="close kept-alive connections that are doing nothing",
        w_c_force="never hang forever",
        w_c_crash="the process is in an unknown state: log and stop; the supervisor restarts it",
        w_c_port0="port 0: the system picks a free port, so tests never clash",
        w_c_level="messages below the configured level are dropped",
        w_t_primes="counts the primes", w_t_hello="answers /hello", w_t_limit="refuses a bad limit",
        w_t_export="streams the export as CSV",
        w_d_script="script starts", w_d_end="script ends", w_d_tick="process.nextTick",
        w_d_promise="promise callback", w_d_timer="timer (0 ms)", w_d_late="timer asked for 10 ms, ran after",
        w_d_busy="busy for 200 ms", w_d_stock="stock", w_d_price="price", w_d_reviews="reviews",
        w_d_seq="one after another", w_d_par="all at once", w_d_settled="one fails, the others still count",
        w_d_failed="failed", w_d_down="the reviews service is down", w_d_timeout="with a time limit of 250 ms",
        w_d_skipped="skipped (too slow)", w_d_orders="orders written to orders.csv",
        w_d_total="total", w_d_memory="peak memory", w_d_lines="lines",
        w_s_strip="Node runs the TypeScript file: the types are removed, nothing is checked",
        w_s_enum="An enum is not just a type: it needs code, so plain Node refuses it",
        w_s_check="tsc checks the types (and, with erasableSyntaxOnly, refuses the enum too)",
        w_s_loop="The order things run in",
        w_s_block="One slow request (a CPU count) and one quick one, sent at the same moment",
        w_s_worker="The same two requests, with the count in a worker thread",
        w_s_conc="Waiting for three services",
        w_s_make="A million orders, about 24 MB", w_s_read="Read the whole file, then add up",
        w_s_stream="Read it as a stream, line by line",
        w_s_export="An export streamed as it is made: no Content-Length, chunked instead",
        w_s_noenv="Started without its settings: it refuses to start, and says why",
        w_s_env="With the settings from .env",
        w_s_kill="A long request is running when the server is told to stop (Ctrl+C)",
        w_s_term="Terminal 2: the request still gets its answer",
        w_s_test="Node's own test runner finds the *.test.ts files and runs them",
    ),
    "ar": dict(
        w_hello="أهلاً من متجر Bit", w_e_limit="يجب أن يكون limit عدداً صحيحاً من 1 إلى 10000000",
        w_e_none="لا شيء هنا", w_e_500="حدث خطأ عندنا",
        w_listen="يستمع على", w_stop="لا اتصالات جديدة، وننهي الطلبات الجارية",
        w_closed="انتهت كل الطلبات، إلى اللقاء", w_force="ما زالت طلبات تعمل بعد 10 ثوانٍ، نتوقف على أي حال",
        w_crash="خطأ غير متوقع، نتوقف", w_bad_config="الإعدادات غير صالحة:",
        w_c_worker="يعمل في خيط خاص به، فلا يوقف العدّ الطويل حلقة الأحداث أبداً.",
        w_c_count="يعدّ الأعداد الأولية حتى limit بالطريقة البطيئة: عمل معالج خالص.",
        w_c_one="خيط لكل طلب: بسيط، ومناسب للأعمال الثقيلة النادرة",
        w_c_rows="تُصنع الصفوف واحداً واحداً، حين يكون العميل مستعداً لها",
        w_c_env="لا يحمل process.env إلا نصوصاً: حوّلها وافحصها مرة واحدة عند البدء",
        w_c_frozen="للقراءة فقط: لا شيء يستطيع تغيير الإعدادات لاحقاً",
        w_c_stop="توقف عن قبول الاتصالات، ودع الطلبات الجارية تنتهي",
        w_c_idle="أغلق الاتصالات المفتوحة التي لا تفعل شيئاً",
        w_c_force="لا تعلق إلى الأبد",
        w_c_crash="العملية في حال مجهولة: سجّل وتوقف، والمشرف يعيد تشغيلها",
        w_c_port0="المنفذ 0: يختار النظام منفذاً حراً، فلا تتصادم الاختبارات أبداً",
        w_c_level="الرسائل الأدنى من المستوى المضبوط تُهمل",
        w_t_primes="يعدّ الأعداد الأولية", w_t_hello="يرد على /hello", w_t_limit="يرفض limit غير الصالح",
        w_t_export="يبث التصدير بصيغة CSV",
        w_d_script="يبدأ السكربت", w_d_end="ينتهي السكربت", w_d_tick="process.nextTick",
        w_d_promise="دالة الوعد", w_d_timer="المؤقت (0 ms)", w_d_late="مؤقت طلب 10 ms، فعمل بعد",
        w_d_busy="مشغول 200 ms", w_d_stock="المخزون", w_d_price="السعر", w_d_reviews="المراجعات",
        w_d_seq="واحداً بعد الآخر", w_d_par="كلها معاً", w_d_settled="يفشل واحد، ويبقى الباقي",
        w_d_failed="فشل", w_d_down="خدمة المراجعات متوقفة", w_d_timeout="بمهلة 250 ms",
        w_d_skipped="تُخطّيت (بطيئة جداً)", w_d_orders="طلب في الملف orders.csv",
        w_d_total="الإجمالي", w_d_memory="أقصى ذاكرة", w_d_lines="سطر",
        w_s_strip="يشغّل Node ملف TypeScript: تُحذف الأنواع، ولا يُفحص شيء",
        w_s_enum="التعداد enum ليس نوعاً فقط: يحتاج كوداً، فيرفضه Node وحده",
        w_s_check="يفحص tsc الأنواع (ومع erasableSyntaxOnly يرفض التعداد أيضاً)",
        w_s_loop="الترتيب الذي تعمل به الأشياء",
        w_s_block="طلب بطيء (عدّ على المعالج) وطلب سريع، يُرسلان في اللحظة نفسها",
        w_s_worker="الطلبان نفسهما، والعدّ في خيط عامل",
        w_s_conc="انتظار ثلاث خدمات",
        w_s_make="مليون طلب، نحو 24 MB", w_s_read="اقرأ الملف كله، ثم اجمع",
        w_s_stream="اقرأه تدفقاً، سطراً سطراً",
        w_s_export="تصدير يُبث وهو يُصنع: لا Content-Length، بل chunked",
        w_s_noenv="بدأ دون إعداداته: يرفض أن يبدأ، ويقول لماذا",
        w_s_env="بالإعدادات من الملف ‎.env",
        w_s_kill="طلب طويل يعمل حين يُطلب من الخادم أن يتوقف (Ctrl+C)",
        w_s_term="النافذة 2: الطلب يأخذ جوابه رغم ذلك",
        w_s_test="مشغّل الاختبارات في Node يجد ملفات ‎*.test.ts ويشغّلها",
    ),
}

FILES = {
    "package.json": '''{
  "name": "bit-shop",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "engines": { "node": ">=22.18" },
  "scripts": {
    "dev": "node --watch --env-file=.env src/server.ts",
    "start": "node --env-file=.env src/server.ts",
    "check": "tsc",
    "test": "node --env-file=.env.test --test --test-reporter=spec"
  },
  "dependencies": {
    "zod": "^4.6.7"
  },
  "devDependencies": {
    "@types/node": "^22.20.5",
    "typescript": "^7.0.2"
  }
}
''',
    "tsconfig.json": '''{
  "compilerOptions": {
    "target": "es2024",
    "module": "nodenext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "erasableSyntaxOnly": true,
    "verbatimModuleSyntax": true,
    "types": ["node"]
  },
  "include": ["src", "demos"]
}
''',
    ".env": '''PORT=3000
LOG_LEVEL=info
ALLOWED_ORIGINS=http://localhost:5173
''',
    ".env.test": '''PORT=3000
LOG_LEVEL=warn
ALLOWED_ORIGINS=http://localhost:5173
''',
    "src/config.ts": '''import { z } from "zod";

// {w_c_env}
const Env = z.object({
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
  ALLOWED_ORIGINS: z
    .string()
    .transform((list) => list.split(",").map((origin) => origin.trim()))
    .pipe(z.array(z.url())),
});

const parsed = Env.safeParse(process.env);
if (!parsed.success) {
  console.error("{w_bad_config}\\n" + z.prettifyError(parsed.error));
  process.exit(1);
}

// {w_c_frozen}
export const config = Object.freeze(parsed.data);
export type Config = typeof config;
''',
    "src/log.ts": '''import { config } from "./config.ts";

const LEVELS = ["debug", "info", "warn", "error"] as const;
type Level = (typeof LEVELS)[number];

export function log(level: Level, message: string): void {
  // {w_c_level}
  if (LEVELS.indexOf(level) < LEVELS.indexOf(config.LOG_LEVEL)) return;
  const line = `${level.padEnd(5)} ${message}`;
  if (level === "error") console.error(line);
  else console.log(line);
}
''',
    "src/primes.ts": '''// {w_c_count}
export function countPrimes(limit: number): number {
  let count = 0;
  for (let n = 2; n <= limit; n++) {
    let prime = true;
    for (let d = 2; d * d <= n; d++) {
      if (n % d === 0) {
        prime = false;
        break;
      }
    }
    if (prime) count++;
  }
  return count;
}
''',
    "src/primes-worker.ts": '''// {w_c_worker}
import { parentPort, workerData } from "node:worker_threads";
import { countPrimes } from "./primes.ts";

parentPort?.postMessage(countPrimes(workerData as number));
''',
    "src/app.ts": '''import { createServer, type ServerResponse } from "node:http";
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

// {w_c_one}
function countInWorker(limit: number): Promise<number> {
  return new Promise((resolve, reject) => {
    const worker = new Worker(new URL("./primes-worker.ts", import.meta.url), {
      workerData: limit,
    });
    worker.once("message", resolve);
    worker.once("error", reject);
  });
}

// {w_c_rows}
async function* orderRows(count: number) {
  yield "id,customer,total\\n";
  for (let id = 1; id <= count; id++) {
    yield `${id},customer-${id % 97},${(id * 7919) % 100000}\\n`;
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
        return json(res, 200, { message: "{w_hello}" });
      }
      if (url.pathname === "/primes") {
        const limit = Number(url.searchParams.get("limit"));
        if (!Number.isInteger(limit) || limit < 1 || limit > 10_000_000) {
          return json(res, 422, { error: { code: "invalid", message: "{w_e_limit}" } });
        }
        const primes = await countInWorker(limit);
        return json(res, 200, { limit, primes, ms: Math.round(performance.now() - start) });
      }
      if (url.pathname === "/export") {
        res.writeHead(200, { "Content-Type": "text/csv; charset=utf-8" });
        return await pipeline(Readable.from(orderRows(100_000)), res);
      }
      json(res, 404, { error: { code: "not_found", message: "{w_e_none}" } });
    } catch (error) {
      log("error", String(error));
      if (!res.headersSent) {
        json(res, 500, { error: { code: "server_error", message: "{w_e_500}" } });
      } else {
        res.destroy();
      }
    }
  });
}
''',
    "src/server.ts": '''import { config } from "./config.ts";
import { createApp } from "./app.ts";
import { log } from "./log.ts";

const server = createApp();
server.requestTimeout = 30_000;
server.listen(config.PORT, () => {
  log("info", `{w_listen} http://localhost:${config.PORT}`);
});

function shutdown(signal: string): void {
  log("info", `${signal}: {w_stop}`);
  server.close(() => {
    // {w_c_stop}
    log("info", "{w_closed}");
    process.exit(0);
  });
  // {w_c_idle}
  server.closeIdleConnections();
  setTimeout(() => {
    log("error", "{w_force}");
    process.exit(1);
  }, 10_000).unref(); // {w_c_force}
}
process.once("SIGTERM", () => shutdown("SIGTERM"));
process.once("SIGINT", () => shutdown("SIGINT"));

// {w_c_crash}
process.on("unhandledRejection", (error) => {
  log("error", `{w_crash}: ${String(error)}`);
  process.exit(1);
});
''',
    "src/app.test.ts": '''import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import type { AddressInfo } from "node:net";
import { createApp } from "./app.ts";
import { countPrimes } from "./primes.ts";

const server = createApp();
let base = "";
before(async () => {
  // {w_c_port0}
  await new Promise<void>((resolve) => server.listen(0, resolve));
  base = `http://localhost:${(server.address() as AddressInfo).port}`;
});
after(() => server.close());

test("{w_t_primes}", () => {
  assert.equal(countPrimes(10), 4);
  assert.equal(countPrimes(1), 0);
});

test("{w_t_hello}", async () => {
  const res = await fetch(`${base}/hello`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { message: "{w_hello}" });
});

test("{w_t_limit}", async () => {
  for (const limit of ["0", "abc", "20000000"]) {
    const res = await fetch(`${base}/primes?limit=${limit}`);
    assert.equal(res.status, 422);
  }
});

test("{w_t_export}", async () => {
  const text = await (await fetch(`${base}/export`)).text();
  const lines = text.trim().split("\\n");
  assert.equal(lines[0], "id,customer,total");
  assert.equal(lines.length, 100_001);
});
''',
    "demos/enum.ts": '''enum Status {
  Pending,
  Paid,
}
console.log(Status.Paid);
''',
    "demos/strip.ts": '''type Order = { id: number; total: number };

// a string: wrong, and nobody checks
const order: Order = { id: 1, total: "450" };
console.log(order.total + 50);
''',
    "demos/event-loop.ts": '''import { readFile } from "node:fs/promises";

console.log("{w_d_script}");
setTimeout(() => console.log("{w_d_timer}"), 0);
Promise.resolve().then(() => console.log("{w_d_promise}"));
process.nextTick(() => console.log("{w_d_tick}"));
console.log("{w_d_end}");

// wait for some I/O, then a second experiment
await readFile(import.meta.filename);
const asked = performance.now();
setTimeout(() => {
  const late = Math.round(performance.now() - asked);
  console.log(`{w_d_late} ${late} ms`);
}, 10);
const until = performance.now() + 200;
while (performance.now() < until); // {w_d_busy}
''',
    "demos/concurrency.ts": '''import { setTimeout as sleep } from "node:timers/promises";

// Three slow services, as a real API would call over the network.
const stock = (signal?: AbortSignal) => sleep(300, 7, { signal });
const price = (signal?: AbortSignal) => sleep(200, 45000, { signal });
const reviews = (signal?: AbortSignal) => sleep(400, 4.5, { signal });

async function timed(label: string, work: () => Promise<unknown>) {
  const start = performance.now();
  const result = await work();
  console.log(`${label}: ${Math.round(performance.now() - start)} ms`, result);
}

await timed("{w_d_seq}", async () => {
  return [await stock(), await price(), await reviews()];
});

await timed("{w_d_par}", () => Promise.all([stock(), price(), reviews()]));

const down = () => Promise.reject(new Error("{w_d_down}"));
await timed("{w_d_settled}", async () => {
  const results = await Promise.allSettled([stock(), price(), down()]);
  return results.map((r) => (r.status === "fulfilled" ? r.value : "{w_d_failed}"));
});

await timed("{w_d_timeout}", async () => {
  const limit = AbortSignal.timeout(250);
  const results = await Promise.allSettled([stock(), price(), reviews(limit)]);
  return results.map((r) =>
    r.status === "fulfilled" ? r.value : "{w_d_skipped}",
  );
});
''',
    "demos/make-orders.ts": '''import { createWriteStream } from "node:fs";
import { once } from "node:events";

const file = createWriteStream("orders.csv");
file.write("id,customer,total\\n");
for (let id = 1; id <= 1_000_000; id++) {
  const line = `${id},customer-${id % 97},${(id * 7919) % 100000}\\n`;
  // write() returns false when the buffer is full: wait until it drains
  if (!file.write(line)) await once(file, "drain");
}
file.end();
await once(file, "finish");
console.log("1000000 {w_d_orders}");
''',
    "demos/total-read.ts": '''import { readFile } from "node:fs/promises";

const text = await readFile("orders.csv", "utf8"); // the whole file in memory
let total = 0;
for (const line of text.split("\\n").slice(1)) {
  if (line) total += Number(line.split(",")[2]);
}
const peak = Math.round(process.resourceUsage().maxRSS / 1024);
console.log(`{w_d_total}: ${total}, {w_d_memory}: ${peak} MB`);
''',
    "demos/total-stream.ts": '''import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";

const lines = createInterface({ input: createReadStream("orders.csv") });
let total = 0;
let first = true;
for await (const line of lines) {
  if (first) {
    first = false; // the header
    continue;
  }
  total += Number(line.split(",")[2]);
}
const peak = Math.round(process.resourceUsage().maxRSS / 1024);
console.log(`{w_d_total}: ${total}, {w_d_memory}: ${peak} MB`);
''',
    "demos/blocking.ts": '''import { createServer } from "node:http";
import { countPrimes } from "../src/primes.ts";

createServer((req, res) => {
  const url = new URL(req.url ?? "/", "http://localhost");
  if (url.pathname === "/primes") {
    const primes = countPrimes(Number(url.searchParams.get("limit"))); // blocks!
    return res.end(JSON.stringify({ primes }));
  }
  res.end(JSON.stringify({ message: "hello" }));
}).listen(3001);
''',
    "answers/all-fails.ts": '''import { setTimeout as sleep } from "node:timers/promises";

const start = performance.now();
const ms = () => `${Math.round(performance.now() - start)} ms`;
const stock = sleep(300, 7).then((value) => {
  console.log(`stock finished anyway at ${ms()}`);
  return value;
});
const price = sleep(200).then(() => {
  throw new Error("price service down");
});
const reviews = sleep(400, 4.5);

try {
  await Promise.all([stock, price, reviews]);
} catch (error) {
  console.log(`Promise.all rejected at ${ms()}: ${(error as Error).message}`);
}
await sleep(300);
''',
    "answers/pool-worker.ts": '''import { parentPort } from "node:worker_threads";
import { countPrimes } from "../src/primes.ts";

parentPort?.on("message", (limit: number) => {
  parentPort?.postMessage(countPrimes(limit));
});
''',
    "answers/pool.ts": '''import { Worker } from "node:worker_threads";

type Job = { data: unknown; resolve: (value: unknown) => void; reject: (error: unknown) => void };

// A fixed number of workers, started once and reused; jobs wait in a queue.
export class WorkerPool {
  #file: URL;
  #idle: Worker[] = [];
  #queue: Job[] = [];

  constructor(file: URL, size: number) {
    this.#file = file;
    for (let i = 0; i < size; i++) this.#idle.push(new Worker(file));
  }

  run(data: unknown): Promise<unknown> {
    return new Promise((resolve, reject) => {
      this.#queue.push({ data, resolve, reject });
      this.#next();
    });
  }

  #next(): void {
    if (!this.#idle.length || !this.#queue.length) return;
    const worker = this.#idle.pop() as Worker;
    const job = this.#queue.shift() as Job;
    const onMessage = (value: unknown) => {
      worker.off("error", onError);
      this.#idle.push(worker);
      job.resolve(value);
      this.#next();
    };
    const onError = (error: unknown) => {
      worker.off("message", onMessage);
      this.#idle.push(new Worker(this.#file)); // a crashed worker is gone: start a fresh one
      job.reject(error);
      this.#next();
    };
    worker.once("message", onMessage);
    worker.once("error", onError);
    worker.postMessage(job.data);
  }

  async close(): Promise<void> {
    await Promise.all(this.#idle.map((worker) => worker.terminate()));
  }
}
''',
    "answers/pool-demo.ts": '''import { Worker } from "node:worker_threads";
import { WorkerPool } from "./pool.ts";

const jobs = 100;
const limit = 20_000;

let start = performance.now();
for (let i = 0; i < jobs; i++) {
  await new Promise((resolve) => {
    const worker = new Worker(new URL("../src/primes-worker.ts", import.meta.url), {
      workerData: limit,
    });
    worker.once("message", resolve);
  });
}
console.log(`a new thread per job: ${Math.round(performance.now() - start)} ms`);

const pool = new WorkerPool(new URL("./pool-worker.ts", import.meta.url), 4);
start = performance.now();
for (let i = 0; i < jobs; i++) await pool.run(limit);
console.log(`a pool of 4 threads:  ${Math.round(performance.now() - start)} ms`);
await pool.close();
''',
}


def record(folder, t):
    s = Session(folder)
    env_noproxy = dict(CLEAN)

    s.note(t["w_s_strip"])
    s.run("node demos/strip.ts")
    s.note(t["w_s_enum"])
    s.run("node demos/enum.ts 2>&1 | grep SyntaxError", check=False)
    s.note(t["w_s_check"])
    s.run("npx tsc", check=False)
    s.save(folder / "types.sh")

    s.note(t["w_s_loop"])
    s.run("node demos/event-loop.ts")
    s.save(folder / "event-loop.sh")

    both = ("curl -s 'localhost:{p}/primes?limit=5000000' -w ' %{{time_total}}s\\n' & "
            "sleep 0.05; curl -s localhost:{p}/hello -w ' %{{time_total}}s\\n'; wait")
    with Server("node demos/blocking.ts", folder, "http://localhost:3001/ready"):
        s.note(t["w_s_block"])
        s.run(both.format(p=3001))
        s.save(folder / "blocking.sh")
    with Server("node --env-file=.env src/server.ts", folder, "http://localhost:3000/ready") as srv:
        s.note(t["w_s_worker"])
        s.run(both.format(p=3000))
        s.save(folder / "worker.sh")
        s.note(t["w_s_export"])
        s.run("curl -s -D - localhost:3000/export | head -n 12")
        s.save(folder / "export.sh")

    s.note(t["w_s_conc"])
    s.run("node demos/concurrency.ts")
    s.save(folder / "concurrency.sh")

    s.note(t["w_s_make"])
    s.run("node demos/make-orders.ts")
    s.run("ls -lh orders.csv | awk '{print $5, $9}'")
    s.note(t["w_s_read"])
    s.run("node demos/total-read.ts")
    s.note(t["w_s_stream"])
    s.run("node demos/total-stream.ts")
    s.save(folder / "streams.sh")
    (folder / "orders.csv").unlink()

    s.note(t["w_s_noenv"])
    s.run("PORT=abc ALLOWED_ORIGINS=localhost node src/server.ts", check=False)
    s.save(folder / "config.sh")

    # Graceful shutdown: a long request is running when SIGTERM arrives.
    server = subprocess.Popen(["npm", "start"], cwd=folder, env=env_noproxy, start_new_session=True,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for _ in range(100):
        if subprocess.run(["curl", "-s", "-o", "/dev/null", "localhost:3000/hello"], env=env_noproxy).returncode == 0:
            break
        time.sleep(0.1)
    client = subprocess.Popen(["bash", "-c", "curl -s 'localhost:3000/primes?limit=5000000' -w ' %{http_code}\\n'"],
                              cwd=folder, env=env_noproxy, stdout=subprocess.PIPE, text=True)
    time.sleep(0.4)
    os.killpg(server.pid, signal.SIGINT)  # what Ctrl+C sends; a supervisor sends SIGTERM, handled the same way
    log = server.communicate(timeout=30)[0]
    answer = client.communicate(timeout=30)[0]
    lines = [l for l in log.strip().split("\n") if "/hello" not in l]  # the start-up check
    s.note(t["w_s_kill"])
    s.lines.append("$ npm start")
    for line in lines:
        if "SIGINT:" in line:
            s.lines.append("^C")
        s.lines.append(line)
    s.save(folder / "shutdown.sh")
    s.note(t["w_s_term"])
    s.lines.append("$ curl -s 'localhost:3000/primes?limit=5000000' -w ' %{http_code}\\n'")
    s.add(answer)
    s.save(folder / "shutdown-client.sh")

    s.run("node answers/all-fails.ts")
    s.run("node answers/pool-demo.ts")
    s.save(folder / "answers.sh")

    s.note(t["w_s_test"])
    s.run("npm test")
    s.save(folder / "test.sh")


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    os.symlink(B3 / "node_modules", folder / "node_modules")
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
