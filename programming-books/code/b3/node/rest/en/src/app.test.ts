import { test } from "node:test";
import assert from "node:assert/strict";
import { buildApp } from "./app.ts";

type ProductJson = { id: number; stock: number; price: { amount: number } };

test("walks every page without repeats or gaps", async () => {
  const app = await buildApp();
  const seen: number[] = [];
  let cursor: string | null = null;
  do {
    const url: string = `/v1/products?limit=5${cursor ? `&cursor=${cursor}` : ""}`;
    const page = (await app.inject(url)).json();
    seen.push(...page.data.map((p: ProductJson) => p.id));
    cursor = page.next_cursor;
  } while (cursor);
  assert.deepEqual(seen, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
});

test("sorts by price, highest first", async () => {
  const app = await buildApp();
  const page = (await app.inject("/v1/products?sort=-price&limit=3")).json();
  const prices = page.data.map((p: ProductJson) => p.price.amount);
  assert.deepEqual(prices, [45000, 30000, 21000]);
});

test("replays an order instead of creating it twice", async () => {
  const app = await buildApp();
  const order = {
    method: "POST" as const,
    url: "/v1/orders",
    headers: { "idempotency-key": "test-key-0001" },
    payload: { items: [{ product_id: 1, quantity: 2 }] },
  };
  const first = await app.inject(order);
  const second = await app.inject(order);
  assert.equal(first.statusCode, 201);
  assert.equal(second.headers["idempotent-replayed"], "true");
  assert.deepEqual(second.json(), first.json());
  assert.equal((await app.inject("/v1/products/1")).json().stock, 8);
});

test("refuses a stale update with 412", async () => {
  const app = await buildApp();
  const patch = (etag: string) =>
    app.inject({
      method: "PATCH",
      url: "/v1/products/2",
      headers: { "if-match": etag },
      payload: { stock: 3 },
    });
  assert.equal((await patch('"1"')).statusCode, 200);
  assert.equal((await patch('"1"')).statusCode, 412);
});

test("answers 422 with every invalid field", async () => {
  const app = await buildApp();
  const res = await app.inject({
    method: "POST",
    url: "/v1/orders",
    headers: { "idempotency-key": "test-key-0002" },
    payload: { items: [{ product_id: 1, quantity: 0 }], coupon: "FREE" },
  });
  assert.equal(res.statusCode, 422);
  assert.equal(
    res.headers["content-type"],
    "application/problem+json; charset=utf-8",
  );
  assert.equal(res.json().errors.length, 2);
});
