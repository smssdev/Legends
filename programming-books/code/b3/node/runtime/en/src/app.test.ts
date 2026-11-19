import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import type { AddressInfo } from "node:net";
import { createApp } from "./app.ts";
import { countPrimes } from "./primes.ts";

const server = createApp();
let base = "";
before(async () => {
  // port 0: the system picks a free port, so tests never clash
  await new Promise<void>((resolve) => server.listen(0, resolve));
  base = `http://localhost:${(server.address() as AddressInfo).port}`;
});
after(() => server.close());

test("counts the primes", () => {
  assert.equal(countPrimes(10), 4);
  assert.equal(countPrimes(1), 0);
});

test("answers /hello", async () => {
  const res = await fetch(`${base}/hello`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { message: "Hello from Bit's shop" });
});

test("refuses a bad limit", async () => {
  for (const limit of ["0", "abc", "20000000"]) {
    const res = await fetch(`${base}/primes?limit=${limit}`);
    assert.equal(res.status, 422);
  }
});

test("streams the export as CSV", async () => {
  const text = await (await fetch(`${base}/export`)).text();
  const lines = text.trim().split("\n");
  assert.equal(lines[0], "id,customer,total");
  assert.equal(lines.length, 100_001);
});
