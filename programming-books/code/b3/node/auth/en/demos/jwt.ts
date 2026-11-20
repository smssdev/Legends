import { createHmac, timingSafeEqual } from "node:crypto";

const secret = "a secret only the server knows";
const b64 = (value: object) =>
  Buffer.from(JSON.stringify(value)).toString("base64url");
const sign = (data: string) =>
  createHmac("sha256", secret).update(data).digest("base64url");

// a JWT: header and payload in base64url, then an HMAC of both with the server's secret
const header = b64({ alg: "HS256", typ: "JWT" });
const payload = b64({ sub: 2, role: "customer", exp: 1795000000 });
const token = `${header}.${payload}.${sign(`${header}.${payload}`)}`;
console.log("token:", token);

// anyone can read the payload: it is encoded, not encrypted
const read = (part: string) =>
  JSON.parse(Buffer.from(part, "base64url").toString());
console.log("payload, read without the key:", read(token.split(".")[1] ?? ""));

const valid = (jwt: string) => {
  const [h, p, signature = ""] = jwt.split(".");
  const expected = Buffer.from(sign(`${h}.${p}`));
  const given = Buffer.from(signature);
  return given.length === expected.length && timingSafeEqual(given, expected);
};
console.log("signature valid:", valid(token));
// change the payload, keep the signature
const forged = b64({ sub: 2, role: "admin", exp: 1795000000 });
console.log(
  "tampered token valid:",
  valid(`${header}.${forged}.${token.split(".")[2]}`),
);
