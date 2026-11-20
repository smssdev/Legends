import pg from "pg";
import { createClient } from "redis";

const db = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop" });
const redis = await createClient({ url: "redis://localhost:6379" }).connect();
type Product = { id: string; name: string; price: number };

// الاستعلام البطيء: pg_sleep تمثل تقريراً ثقيلاً أو ربطاً بين جداول كبيرة
async function productFromDb(id: number): Promise<Product> {
  const sql = "SELECT id, name, price FROM products, pg_sleep(0.2) WHERE id = $1";
  return (await db.query(sql, [id])).rows[0];
}

// التخزين جانباً: ابحث في Redis أولاً؛ وعند الغياب اسأل قاعدة البيانات واحفظ الجواب
async function product(id: number) {
  const key = `product:${id}`;
  const cached = await redis.get(key);
  if (cached !== null) return { product: JSON.parse(cached) as Product, from: "Redis" };
  const fresh = await productFromDb(id);
  // يُنسى بعد 60 ثانية، حتى لو لم يحذفه أحد
  await redis.set(key, JSON.stringify(fresh), { EX: 60 });
  return { product: fresh, from: "PostgreSQL" };
}

// تغيير البيانات: حدّث قاعدة البيانات أولاً، ثم احذف النسخة المخزنة
async function setPrice(id: number, price: number) {
  await db.query("UPDATE products SET price = $1 WHERE id = $2", [price, id]);
  await redis.del(`product:${id}`);
}

async function timed(label: string, id: number) {
  const start = performance.now();
  const { product: p, from } = await product(id);
  const ms = Math.round(performance.now() - start);
  console.log(`${label.padEnd(16)} ${p.name}, ${p.price}, من ${from} في ${ms} ms`);
}

await redis.del("product:1");
await timed("الطلب الأول", 1);
await timed("الطلب الثاني", 1);
await timed("الطلب الثالث", 1);
await setPrice(1, 47000);
console.log("تغير السعر إلى 47000، وحُذفت النسخة المخزنة");
await timed("بعد التغيير", 1);
console.log("الثواني الباقية في Redis:", await redis.ttl("product:1"));
await redis.close();
await db.end();
