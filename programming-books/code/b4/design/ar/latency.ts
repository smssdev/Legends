import { createHash, scryptSync } from "node:crypto";
import {
  closeSync,
  fsyncSync,
  openSync,
  readFileSync,
  writeFileSync,
  writeSync,
} from "node:fs";
import { createServer } from "node:http";
import pg from "pg";

// شغّل كل عملية مرات كثيرة واحتفظ بالوسيط: تشغيل واحد لا يثبت شيئاً
async function median(times: number, work: () => unknown) {
  const runs: number[] = [];
  for (let i = 0; i < times; i++) {
    const start = process.hrtime.bigint();
    await work();
    runs.push(Number(process.hrtime.bigint() - start));
  }
  return runs.sort((a, b) => a - b)[Math.floor(runs.length / 2)]!;
}

const show = (ns: number) =>
  ns < 1_000
    ? `${ns} ns`
    : ns < 1_000_000
      ? `${(ns / 1_000).toFixed(1)} µs`
      : `${(ns / 1_000_000).toFixed(1)} ms`;

const map = new Map(Array.from({ length: 100_000 }, (_, i) => [`key${i}`, i]));
const json = JSON.stringify(
  Array.from({ length: 20 }, (_, i) => ({ id: i, name: `item ${i}` })),
);
const kb = Buffer.alloc(1024, 7);
writeFileSync("data.bin", Buffer.alloc(4096, 1));
readFileSync("data.bin");
const server = createServer((_req, res) => res.end("ok")).listen(4100);
const db = new pg.Client({ connectionString: process.env.DATABASE_URL });
await db.connect();

const rows: [string, number][] = [
  ["البحث عن مفتاح في Map", await median(100_000, () => map.get("key5000"))],
  ["تحليل 1 KB من JSON", await median(10_000, () => JSON.parse(json))],
  [
    "SHA-256 لـ 1 KB",
    await median(10_000, () => createHash("sha256").update(kb).digest()),
  ],
  [
    "قراءة 4 KB من ملف في الذاكرة المؤقتة",
    await median(10_000, () => readFileSync("data.bin")),
  ],
  [
    "طلب HTTP إلى localhost",
    await median(1_000, () => fetch("http://localhost:4100").then((r) => r.text())),
  ],
  [
    "SELECT 1 في PostgreSQL (localhost)",
    await median(1_000, () => db.query("SELECT 1")),
  ],
  [
    "كتابة 4 KB وfsync إلى القرص",
    await median(200, () => {
      const fd = openSync("data.bin", "w");
      writeSync(fd, kb);
      fsyncSync(fd);
      closeSync(fd);
    }),
  ],
  [
    "بصمة كلمة مرور بـ scrypt",
    await median(20, () =>
      scryptSync("a long password", "salt", 32, {
        N: 2 ** 15,
        maxmem: 64 * 1024 * 1024,
      }),
    ),
  ],
];

console.log("العملية".padEnd(38), "الوسيط");
for (const [name, ns] of rows) console.log(name.padEnd(38), show(ns));
server.close();
await db.end();
