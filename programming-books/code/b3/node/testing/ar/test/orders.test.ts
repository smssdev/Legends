import assert from "node:assert/strict";
import { after, before, beforeEach, mock, test } from "node:test";
import { sql } from "kysely";
import { buildApp } from "../src/app.ts";
import { connect, SCHEMA } from "../src/db.ts";

// لكل ملف اختبار مخططه: الملفات تعمل بالتوازي دون أن يمس أحدها الآخر
const schema = `test_${process.pid}`;
const db = connect(schema);
// بديل اختبار: يسجّل الاستدعاءات بدل إرسال البريد
const mailer = { send: mock.fn(async (_to: string, _subject: string) => {}) };
const app = buildApp(db, mailer);

before(async () => {
  await sql
    .raw(`CREATE SCHEMA ${schema}; SET search_path = ${schema}; ${SCHEMA}`)
    .execute(db);
});
beforeEach(async () => {
  await sql`TRUNCATE orders RESTART IDENTITY; DELETE FROM products`.execute(db);
  await db
    .insertInto("products")
    .values({ id: 1, name: "Kit", price: 45000, stock: 3 })
    .execute();
  mailer.send.mock.resetCalls();
});
after(async () => {
  await sql.raw(`DROP SCHEMA ${schema} CASCADE`).execute(db);
  await Promise.all([app.close(), db.destroy()]);
});

const order = (quantity: number) =>
  app.inject({
    method: "POST",
    url: "/orders",
    payload: { email: "sara@example.com", productId: 1, quantity, code: "SAVE10" },
  });

test("ينشئ طلباً بالمجموع الصحيح، ويرسل تأكيداً واحداً", async () => {
  const res = await order(2);
  assert.equal(res.statusCode, 201);
  assert.deepEqual(res.json(), { id: 1, total: 92340 });
  const { stock } = await db
    .selectFrom("products")
    .select("stock")
    .executeTakeFirstOrThrow();
  assert.equal(stock, 1);
  assert.equal(mailer.send.mock.callCount(), 1);
  assert.deepEqual(mailer.send.mock.calls[0]?.arguments, [
    "sara@example.com",
    "Order 1",
  ]);
});

test("يرفض طلباً أكبر من المخزون، ولا يغيّر شيئاً", async () => {
  const res = await order(4);
  assert.equal(res.statusCode, 409);
  const orders = await db.selectFrom("orders").selectAll().execute();
  assert.equal(orders.length, 0);
  assert.equal(mailer.send.mock.callCount(), 0);
});
