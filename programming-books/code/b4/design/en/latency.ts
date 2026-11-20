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

// run each operation many times and keep the median: one run proves nothing
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
  ["look up a key in a Map", await median(100_000, () => map.get("key5000"))],
  ["parse 1 KB of JSON", await median(10_000, () => JSON.parse(json))],
  [
    "SHA-256 of 1 KB",
    await median(10_000, () => createHash("sha256").update(kb).digest()),
  ],
  [
    "read 4 KB from a cached file",
    await median(10_000, () => readFileSync("data.bin")),
  ],
  [
    "HTTP request to localhost",
    await median(1_000, () => fetch("http://localhost:4100").then((r) => r.text())),
  ],
  [
    "PostgreSQL SELECT 1 (localhost)",
    await median(1_000, () => db.query("SELECT 1")),
  ],
  [
    "write 4 KB and fsync to disk",
    await median(200, () => {
      const fd = openSync("data.bin", "w");
      writeSync(fd, kb);
      fsyncSync(fd);
      closeSync(fd);
    }),
  ],
  [
    "hash a password with scrypt",
    await median(20, () =>
      scryptSync("a long password", "salt", 32, {
        N: 2 ** 15,
        maxmem: 64 * 1024 * 1024,
      }),
    ),
  ],
];

console.log("operation".padEnd(38), "median");
for (const [name, ns] of rows) console.log(name.padEnd(38), show(ns));
server.close();
await db.end();
