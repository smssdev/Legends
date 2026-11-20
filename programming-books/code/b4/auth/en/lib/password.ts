import { randomBytes, scrypt, timingSafeEqual } from "node:crypto";

const COST = 2 ** 15;

function derive(password: string, salt: Buffer, cost: number) {
  return new Promise<Buffer>((resolve, reject) => {
    const options = { N: cost, r: 8, p: 1, maxmem: 64 * 1024 * 1024 };
    scrypt(password.normalize("NFKC"), salt, 32, options, (error, key) =>
      error ? reject(error) : resolve(key),
    );
  });
}

export async function hashPassword(password: string) {
  const salt = randomBytes(16);
  const key = await derive(password, salt, COST);
  return [
    "scrypt",
    COST,
    salt.toString("base64url"),
    key.toString("base64url"),
  ].join("$");
}

export async function verifyPassword(password: string, stored: string) {
  const [, cost, salt, key] = stored.split("$");
  const expected = Buffer.from(key ?? "", "base64url");
  const actual = await derive(
    password,
    Buffer.from(salt ?? "", "base64url"),
    Number(cost),
  );
  return timingSafeEqual(actual, expected);
}
