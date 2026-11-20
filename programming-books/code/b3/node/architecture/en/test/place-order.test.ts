import assert from "node:assert/strict";
import { test } from "node:test";
import { OutOfStock, TooMany } from "../src/orders/order.ts";
import { makePlaceOrder } from "../src/orders/place-order.ts";
import type { OrderStore } from "../src/orders/ports.ts";

// fakes: the ports, implemented in memory for tests
function fakes(store: OrderStore["place"]) {
  const sent: string[] = [];
  const placeOrder = makePlaceOrder({
    store: { place: store },
    mailer: { send: async (to) => void sent.push(to) },
    clock: { now: () => new Date("2026-11-20T10:00:00Z") },
  });
  return { placeOrder, sent };
}

test("places an order, saves it and sends one email", async () => {
  const saved: unknown[] = [];
  const { placeOrder, sent } = fakes(async (email, items, placedAt) => {
    const lines = items.map((i) => ({ ...i, price: 6000 }));
    saved.push({ email, placedAt });
    return { id: 7, email, lines, total: 12000, placedAt };
  });
  const order = await placeOrder({
    email: "sara@example.com",
    items: [{ productId: 2, quantity: 2 }],
  });
  assert.equal(order.total, 12000);
  assert.deepEqual(saved, [
    { email: "sara@example.com", placedAt: new Date("2026-11-20T10:00:00Z") },
  ]);
  assert.deepEqual(sent, ["sara@example.com"]);
});

test("refuses more than 10 of one product, before touching the store", async () => {
  const { placeOrder } = fakes(async () =>
    assert.fail("the store must not be called"),
  );
  await assert.rejects(
    placeOrder({ email: "a@b.c", items: [{ productId: 1, quantity: 11 }] }),
    TooMany,
  );
});

test("sends no email when the store reports too little stock", async () => {
  const { placeOrder, sent } = fakes(async () => {
    throw new OutOfStock("no");
  });
  await assert.rejects(
    placeOrder({ email: "a@b.c", items: [{ productId: 1, quantity: 9 }] }),
    OutOfStock,
  );
  assert.deepEqual(sent, []);
});
