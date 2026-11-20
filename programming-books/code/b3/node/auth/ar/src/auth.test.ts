import assert from "node:assert/strict";
import { after, test } from "node:test";
import { buildApp } from "./app.ts";
import { db } from "./db.ts";

const app = await buildApp();
after(() => Promise.all([app.close(), db.destroy()]));

async function signIn(email: string, password: string) {
  const res = await app.inject({
    method: "POST",
    url: "/auth/login",
    payload: { email, password },
  });
  return res.json().token as string;
}
const as = (token: string) => ({ authorization: `Bearer ${token}` });

test("يسجّل ويدخل ويقرأ /me", async () => {
  const email = `test-${Date.now()}@example.com`;
  const password = "a long test password";
  const created = await app.inject({
    method: "POST",
    url: "/auth/register",
    payload: { email, name: "Test", password },
  });
  assert.equal(created.statusCode, 201);
  const me = await app.inject({
    url: "/me",
    headers: as(await signIn(email, password)),
  });
  assert.equal(me.json().email, email);
});

test("يرفض /me بلا رمز", async () => {
  assert.equal((await app.inject({ url: "/me" })).statusCode, 401);
});

test("يرفض قائمة المدير لزبون", async () => {
  const omar = await signIn("omar@example.com", "omar-password-2026");
  const res = await app.inject({ url: "/admin/users", headers: as(omar) });
  assert.equal(res.statusCode, 403);
});

test("يخفي طلبات الزبائن الآخرين", async () => {
  const omar = await signIn("omar@example.com", "omar-password-2026");
  const res = await app.inject({ url: "/orders/1", headers: as(omar) });
  assert.equal(res.statusCode, 404);
});

test("يتوقف الرمز عن العمل بعد الخروج", async () => {
  const sara = await signIn("sara@example.com", "sara-password-2026");
  await app.inject({ method: "POST", url: "/auth/logout", headers: as(sara) });
  assert.equal(
    (await app.inject({ url: "/me", headers: as(sara) })).statusCode,
    401,
  );
});
