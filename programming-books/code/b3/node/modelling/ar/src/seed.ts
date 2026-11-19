import { sql } from "kysely";
import { db } from "./db.ts";

await db
  .insertInto("customers")
  .values([
    { name: "سارة", email: "sara@example.com" },
    { name: "عمر", email: "omar@example.com" },
    { name: "لينا", email: "lina@example.com" },
  ])
  .execute();
await db
  .insertInto("products")
  .values([
    { name: "عدة الروبوت", price: 45000, stock: 10, sku: "BIT-0001" },
    { name: "عجلات احتياطية", price: 6000, stock: 25, sku: "BIT-0002" },
    { name: "حزمة بطارية", price: 12500, stock: 8, sku: "BIT-0003" },
    { name: "كابل USB", price: 2500, stock: 80, sku: "BIT-0004" },
  ])
  .execute();
// Sara gets 200 orders of 1 to 3 items, for the N+1 measurement.
await sql`INSERT INTO orders (customer_id, status)
          SELECT 1, 'shipped' FROM generate_series(1, 200)`.execute(db);
await sql`INSERT INTO order_items (order_id, product_id, quantity, price)
          SELECT o.id, p.id, 1, p.price FROM orders o JOIN products p ON p.id <= 1 + o.id % 3`.execute(
  db,
);
console.log("seeded");
await db.destroy();
