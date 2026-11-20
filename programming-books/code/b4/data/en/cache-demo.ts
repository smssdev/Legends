import { book, close, freeSlots } from "./cache.ts";
import { primary } from "./db.ts";

await primary.query("SELECT 1"); // open the connection first, so the timings below are of the queries alone

async function read() {
  const start = performance.now();
  const { from, slots } = await freeSlots(1, "2026-12-01");
  const ms = (performance.now() - start).toFixed(2);
  console.log(`read ${ms} ms  from ${from.padEnd(8)}  ${slots.length} free slots`);
}

await read();
await read();
await read();
await book(1, "2026-12-01", "10:30", "nour@example.com");
console.log("booking made, cache cleared");
await read();
await read();
await close();
