import { setTimeout as sleep } from "node:timers/promises";
import { primary, readerFor, replica, write } from "./db.ts";

const find = "SELECT id FROM bookings WHERE email = $1";

// اكتب في الرئيسية، ثم اسأل النسخة كل نصف ثانية
const start = Date.now();
const { rows } = await write(
  "owner",
  "INSERT INTO bookings (staff_id, starts_at, email) VALUES (1, now(), $1) RETURNING id",
  ["sara@example.com"],
);
const owner = readerFor("owner");
const other = readerFor("someone-else");
const label = (pool: unknown) => (pool === primary ? "primary" : "replica");
const seen = async (pool: typeof primary) =>
  (await pool.query(find, ["sara@example.com"])).rowCount ? "موجود" : "غير موجود";
console.log(
  `صاحب العمل، بعد الحجز مباشرة، يقرأ من ${label(owner)}: ${await seen(owner)}`,
);
console.log(`مستخدم آخر يقرأ من ${label(other)}: ${await seen(other)}`);

for (;;) {
  const found = await replica.query(find, ["sara@example.com"]);
  const ms = Math.round((Date.now() - start) / 500) * 500;
  if (found.rowCount) {
    console.log(`booking ${rows[0]!.id}: على النسخة بعد ~${ms} ms`);
    break;
  }
  console.log(`~${ms} ms: ليس على النسخة بعد`);
  await sleep(500);
}
await primary.end();
await replica.end();
