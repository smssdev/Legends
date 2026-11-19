import { test } from "node:test";
import assert from "node:assert/strict";
import { IdempotencyStore } from "./idempotency.ts";

test("keys belong to one client", () => {
  const store = new IdempotencyStore<number>();
  store.set("client-a", "key-1", "f1", 1);
  assert.equal(store.get("client-a", "key-1")?.result, 1);
  assert.equal(store.get("client-b", "key-1"), undefined);
});

test("keys expire after the time to live", () => {
  let now = 0;
  const store = new IdempotencyStore<number>(1000, () => now);
  store.set("client-a", "key-1", "f1", 1);
  now = 999;
  assert.equal(store.get("client-a", "key-1")?.result, 1);
  now = 1000;
  assert.equal(store.get("client-a", "key-1"), undefined);
});
