import { setTimeout as sleep } from "node:timers/promises";
import { primary, readerFor, replica, write } from "./db.ts";

const find = "SELECT id FROM bookings WHERE email = $1";

// write on the primary, then ask the replica every half second
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
  (await pool.query(find, ["sara@example.com"])).rowCount ? "found" : "not found";
console.log(
  `owner, just after booking, reads from ${label(owner)}: ${await seen(owner)}`,
);
console.log(`another user reads from ${label(other)}: ${await seen(other)}`);

for (;;) {
  const found = await replica.query(find, ["sara@example.com"]);
  const ms = Math.round((Date.now() - start) / 500) * 500;
  if (found.rowCount) {
    console.log(`booking ${rows[0]!.id}: on the replica after ~${ms} ms`);
    break;
  }
  console.log(`~${ms} ms: not on the replica yet`);
  await sleep(500);
}
await primary.end();
await replica.end();
