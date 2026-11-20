import { randomUUID } from "node:crypto";
import { setTimeout as sleep } from "node:timers/promises";
import pg from "pg";
import { createClient } from "redis";

const db = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop" });
const redis = await createClient({ url: "redis://localhost:6379" }).connect();
const mode = process.argv[2] ?? "naive";

async function productFromDb(id: number) {
  // count the database queries in Redis, so every process adds to one number
  await redis.incr("stats:db-queries");
  const sql = "SELECT id, name, price FROM products, pg_sleep(0.2) WHERE id = $1";
  return (await db.query(sql, [id])).rows[0];
}

// delete the lock only if it is still ours, in one step on the server
const RELEASE = `if redis.call("GET", KEYS[1]) == ARGV[1]
  then return redis.call("DEL", KEYS[1]) else return 0 end`;

async function product(id: number) {
  const key = `product:${id}`;
  for (;;) {
    const cached = await redis.get(key);
    if (cached !== null) return JSON.parse(cached);
    if (mode === "naive") break;
    // only the request that gets the lock asks the database; the others wait and look again
    const token = randomUUID(); // a random token: only the owner of the lock may release it
    if (await redis.set(`lock:${key}`, token, { NX: true, PX: 5000 })) {
      try {
        const fresh = await productFromDb(id);
        await redis.set(key, JSON.stringify(fresh), { EX: 60 });
        return fresh;
      } finally {
        await redis.eval(RELEASE, { keys: [`lock:${key}`], arguments: [token] });
      }
    }
    await sleep(50);
  }
  const fresh = await productFromDb(id);
  await redis.set(key, JSON.stringify(fresh), { EX: 60 });
  return fresh;
}

await redis.del(["product:1", "stats:db-queries"]);
const start = performance.now();
await Promise.all(Array.from({ length: 20 }, () => product(1)));
const ms = Math.round(performance.now() - start);
const queries = await redis.get("stats:db-queries");
console.log(`${mode.padEnd(7)} 20 requests, database queries: ${queries}, ${ms} ms`);
await redis.close();
await db.end();
