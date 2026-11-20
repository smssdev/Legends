import { book, close, freeSlots } from "./cache.ts";
import { primary } from "./db.ts";

await primary.query("SELECT 1"); // افتح الاتصال أولاً، فتكون الأزمنة أدناه للاستعلامات وحدها

async function read() {
  const start = performance.now();
  const { from, slots } = await freeSlots(1, "2026-12-01");
  const ms = (performance.now() - start).toFixed(2);
  console.log(`قراءة ${ms} ms  من ${from.padEnd(8)}  ${slots.length} مواعيد متاحة`);
}

await read();
await read();
await read();
await book(1, "2026-12-01", "10:30", "nour@example.com");
console.log("صُنع حجز، وحُذفت الذاكرة");
await read();
await read();
await close();
