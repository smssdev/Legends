import pg from "pg";
import { createClient } from "redis";

const db = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop" });
const redis = await createClient({ url: "redis://localhost:6379" }).connect();
type Product = { id: string; name: string; price: number };

// the slow query: pg_sleep stands for a heavy report or a join over big tables
async function productFromDb(id: number): Promise<Product> {
  const sql = "SELECT id, name, price FROM products, pg_sleep(0.2) WHERE id = $1";
  return (await db.query(sql, [id])).rows[0];
}

// cache-aside: look in Redis first; on a miss, ask the database and keep the answer
async function product(id: number) {
  const key = `product:${id}`;
  const cached = await redis.get(key);
  if (cached !== null) return { product: JSON.parse(cached) as Product, from: "Redis" };
  const fresh = await productFromDb(id);
  // forgotten after 60 seconds, even if nobody deletes it
  await redis.set(key, JSON.stringify(fresh), { EX: 60 });
  return { product: fresh, from: "PostgreSQL" };
}

// changing the data: update the database first, then delete the cached copy
async function setPrice(id: number, price: number) {
  await db.query("UPDATE products SET price = $1 WHERE id = $2", [price, id]);
  await redis.del(`product:${id}`);
}

async function timed(label: string, id: number) {
  const start = performance.now();
  const { product: p, from } = await product(id);
  const ms = Math.round(performance.now() - start);
  console.log(`${label.padEnd(16)} ${p.name}, ${p.price}, from ${from} in ${ms} ms`);
}

await redis.del("product:1");
await timed("first request", 1);
await timed("second request", 1);
await timed("third request", 1);
await setPrice(1, 47000);
console.log("price changed to 47000, cached copy deleted");
await timed("after the change", 1);
console.log("seconds left in Redis:", await redis.ttl("product:1"));
await redis.close();
await db.end();
