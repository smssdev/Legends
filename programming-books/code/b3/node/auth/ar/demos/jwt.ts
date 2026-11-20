import { createHmac, timingSafeEqual } from "node:crypto";

const secret = "a secret only the server knows";
const b64 = (value: object) =>
  Buffer.from(JSON.stringify(value)).toString("base64url");
const sign = (data: string) =>
  createHmac("sha256", secret).update(data).digest("base64url");

// JWT: الرأس والحمولة بـ base64url، ثم HMAC لهما بسر الخادم
const header = b64({ alg: "HS256", typ: "JWT" });
const payload = b64({ sub: 2, role: "customer", exp: 1795000000 });
const token = `${header}.${payload}.${sign(`${header}.${payload}`)}`;
console.log("الرمز:", token);

// أي أحد يقرأ الحمولة: إنها مرمّزة لا مشفّرة
const read = (part: string) =>
  JSON.parse(Buffer.from(part, "base64url").toString());
console.log("الحمولة، مقروءة بلا المفتاح:", read(token.split(".")[1] ?? ""));

const valid = (jwt: string) => {
  const [h, p, signature = ""] = jwt.split(".");
  const expected = Buffer.from(sign(`${h}.${p}`));
  const given = Buffer.from(signature);
  return given.length === expected.length && timingSafeEqual(given, expected);
};
console.log("التوقيع صالح:", valid(token));
// غيّر الحمولة، وأبقِ التوقيع
const forged = b64({ sub: 2, role: "admin", exp: 1795000000 });
console.log(
  "الرمز المعدّل صالح:",
  valid(`${header}.${forged}.${token.split(".")[2]}`),
);
