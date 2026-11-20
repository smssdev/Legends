import assert from "node:assert/strict";
import { test } from "node:test";
import { isExpired } from "../src/baskets.ts";

test("السلة التي لُمست مؤخراً تبقى", (t) => {
  // الساعة وهمية: الاختبار يحرّك الوقت بدل انتظار 30 دقيقة
  t.mock.timers.enable({ apis: ["Date"], now: 0 });
  const touched = Date.now();
  t.mock.timers.tick(29 * 60 * 1000);
  assert.equal(isExpired(touched), false);
});

test("السلة المتروكة 30 دقيقة تُحرَّر", (t) => {
  t.mock.timers.enable({ apis: ["Date"], now: 0 });
  const touched = Date.now();
  t.mock.timers.tick(30 * 60 * 1000);
  assert.equal(isExpired(touched), true);
});
