import { setTimeout as sleep } from "node:timers/promises";
import { createClient } from "redis";

const redis = await createClient({ url: process.env.REDIS_URL }).connect();

// سكربت واحد، يشغّله Redis ذرياً: لا يستطيع عميل آخر أن يفعل شيئاً بين خطواته
const SLIDING = `
  local key, now, window, limit = KEYS[1], tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3])
  -- احذف الطلبات الأقدم من النافذة، وعدّ الباقي، وأضف هذا إن كان مسموحاً
  redis.call("ZREMRANGEBYSCORE", key, 0, now - window)
  if redis.call("ZCARD", key) >= limit then return 0 end
  redis.call("ZADD", key, now, ARGV[4])
  redis.call("PEXPIRE", key, window)
  return 1
`;

export async function allow(client: string, limit = 5, windowMs = 1000) {
  const now = Date.now();
  const id = `${now}-${Math.random()}`;
  const ok = await redis.eval(SLIDING, {
    keys: [`rate:${client}`],
    arguments: [String(now), String(windowMs), String(limit), id],
  });
  return ok === 1;
}

console.log("الطلب", "  ms ", " ");
const start = Date.now();
for (let i = 1; i <= 8; i++) {
  if (i === 7) await sleep(1000);
  const ok = await allow("203.0.113.7");
  const at = String(Math.round((Date.now() - start) / 100) * 100).padStart(5);
  console.log(String(i).padStart(7), at, ok ? "مسموح" : "مرفوض");
}
await redis.quit();
