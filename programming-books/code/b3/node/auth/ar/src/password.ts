import { randomBytes, scrypt, timingSafeEqual } from "node:crypto";

// N = 2^15: عشرات المللي ثواني و32 MB لكل تجزئة، بطء مقصود؛ ارفعه كلما أسرعت الحواسيب
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
  // ملح عشوائي جديد لكل تجزئة: كلمة المرور نفسها لا تعطي التجزئة نفسها أبداً
  const salt = randomBytes(16);
  const key = await derive(password, salt, COST);
  // الخوارزمية والكلفة والملح والمفتاح في نص واحد: التجزئات القديمة تُتحقق بعد تغيير الكلفة
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
  // تقارن كل بايت، فلا يكشف الوقت المستغرق أين أول اختلاف
  return timingSafeEqual(actual, expected);
}
