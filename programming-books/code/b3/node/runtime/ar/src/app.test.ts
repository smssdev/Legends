import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import type { AddressInfo } from "node:net";
import { createApp } from "./app.ts";
import { countPrimes } from "./primes.ts";

const server = createApp();
let base = "";
before(async () => {
  // المنفذ 0: يختار النظام منفذاً حراً، فلا تتصادم الاختبارات أبداً
  await new Promise<void>((resolve) => server.listen(0, resolve));
  base = `http://localhost:${(server.address() as AddressInfo).port}`;
});
after(() => server.close());

test("يعدّ الأعداد الأولية", () => {
  assert.equal(countPrimes(10), 4);
  assert.equal(countPrimes(1), 0);
});

test("يرد على /hello", async () => {
  const res = await fetch(`${base}/hello`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { message: "أهلاً من متجر Bit" });
});

test("يرفض limit غير الصالح", async () => {
  for (const limit of ["0", "abc", "20000000"]) {
    const res = await fetch(`${base}/primes?limit=${limit}`);
    assert.equal(res.status, 422);
  }
});

test("يبث التصدير بصيغة CSV", async () => {
  const text = await (await fetch(`${base}/export`)).text();
  const lines = text.trim().split("\n");
  assert.equal(lines[0], "id,customer,total");
  assert.equal(lines.length, 100_001);
});
