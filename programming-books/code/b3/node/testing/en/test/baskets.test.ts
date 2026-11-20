import assert from "node:assert/strict";
import { test } from "node:test";
import { isExpired } from "../src/baskets.ts";

test("a basket touched recently is kept", (t) => {
  // the clock is mocked: the test moves time instead of waiting 30 minutes
  t.mock.timers.enable({ apis: ["Date"], now: 0 });
  const touched = Date.now();
  t.mock.timers.tick(29 * 60 * 1000);
  assert.equal(isExpired(touched), false);
});

test("a basket left for 30 minutes is released", (t) => {
  t.mock.timers.enable({ apis: ["Date"], now: 0 });
  const touched = Date.now();
  t.mock.timers.tick(30 * 60 * 1000);
  assert.equal(isExpired(touched), true);
});
