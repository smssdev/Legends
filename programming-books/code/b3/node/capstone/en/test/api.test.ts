import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { after, beforeEach, test } from "node:test";
import { Redis } from "ioredis";
import { sql } from "kysely";
import { buildApp } from "../src/app.ts";
import { config } from "../src/config.ts";
import { connect } from "../src/db.ts";

const db = connect();
const redis = new Redis(config.REDIS_URL);
const app = await buildApp({ db, redis });
const schema = readFileSync("schema.sql", "utf8");

// each test starts from the schema file, on its own database
beforeEach(async () => {
  await sql
    .raw(`DROP SCHEMA public CASCADE; CREATE SCHEMA public; ${schema}`)
    .execute(db);
});
after(async () => {
  await app.close();
  await db.destroy();
  await redis.quit();
});

async function signIn() {
  const user = { email: "sara@example.com", password: "a long password" };
  await app.inject({ method: "POST", url: "/auth/register", body: user });
  const res = await app.inject({ method: "POST", url: "/auth/login", body: user });
  return { authorization: `Bearer ${res.json().token}` };
}

const order = (headers: object, key: string, items: object[]) =>
  app.inject({
    method: "POST",
    url: "/orders",
    headers: { ...headers, "idempotency-key": key },
    body: { items },
  });

const stock = async (id: number) =>
  (
    await db
      .selectFrom("products")
      .select("stock")
      .where("id", "=", id)
      .executeTakeFirstOrThrow()
  ).stock;

test("places an order once, however many times the same key is sent", async () => {
  const auth = await signIn();
  const items = [{ product_id: 2, quantity: 3 }];
  const first = await order(auth, "key-0001", items);
  const again = await order(auth, "key-0001", items);
  assert.equal(first.statusCode, 201);
  assert.equal(again.statusCode, 200);
  assert.equal(again.json().id, first.json().id);
  assert.equal(await stock(2), 47);
  const outbox = await db.selectFrom("outbox").selectAll().execute();
  assert.equal(outbox.length, 1);
});

test("refuses a key reused with another body", async () => {
  const auth = await signIn();
  await order(auth, "key-0002", [{ product_id: 2, quantity: 1 }]);
  const res = await order(auth, "key-0002", [{ product_id: 2, quantity: 2 }]);
  assert.equal(res.statusCode, 422);
});

test("takes no stock when one line is short", async () => {
  const auth = await signIn();
  const res = await order(auth, "key-0003", [
    { product_id: 2, quantity: 1 },
    { product_id: 1, quantity: 6 },
  ]);
  assert.equal(res.statusCode, 409);
  assert.equal(await stock(2), 50);
  assert.equal((await db.selectFrom("orders").selectAll().execute()).length, 0);
});

test("refuses an order without a token", async () => {
  const res = await order({}, "key-0004", [{ product_id: 2, quantity: 1 }]);
  assert.equal(res.statusCode, 401);
  assert.equal(
    res.headers["content-type"],
    "application/problem+json; charset=utf-8",
  );
});

test("pages follow each other with no gaps and no repeats", async () => {
  const seen: number[] = [];
  let url = "/products?limit=2";
  for (;;) {
    const body = (await app.inject({ url })).json();
    seen.push(...body.data.map((p: { id: number }) => p.id));
    if (!body.next_cursor) break;
    url = `/products?limit=2&cursor=${body.next_cursor}`;
  }
  assert.deepEqual(seen, [2, 4, 3, 5, 1]);
});
