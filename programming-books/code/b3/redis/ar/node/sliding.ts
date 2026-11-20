import { setTimeout as sleep } from "node:timers/promises";
import { createClient } from "redis";

const LIMIT = 3;
const WINDOW_MS = 2000;
const redis = await createClient({ url: "redis://localhost:6379" }).connect();

// التمرين 5: نافذة منزلقة، عضو في مجموعة مرتبة لكل طلب، ودرجته وقته
async function allow(client: string) {
  const key = `sliding:${client}`;
  const now = Date.now();
  const [, , count] = await redis
    .multi()
    .zRemRangeByScore(key, 0, now - WINDOW_MS)
    .zAdd(key, { score: now, value: `${now}-${Math.random()}` })
    .zCard(key)
    .pExpire(key, WINDOW_MS)
    .exec();
  return Number(count) <= LIMIT;
}

await redis.del("sliding:203.0.113.7");
for (let i = 1; i <= 5; i++) {
  if (i === 5) {
    await sleep(2000);
    console.log("(بعد ثانيتين)");
  }
  const allowed = await allow("203.0.113.7");
  console.log(`الطلب ${i}: ${allowed ? "مسموح" : "مرفوض، 429"}`);
}
await redis.close();
