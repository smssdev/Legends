import { setTimeout as sleep } from "node:timers/promises";
import { createClient } from "redis";

const LIMIT = 3;
const WINDOW_MS = 2000;
const redis = await createClient({ url: "redis://localhost:6379" }).connect();

// exercise 5: a sliding window, one sorted-set member per request, scored by its time
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
    console.log("(2 seconds later)");
  }
  const allowed = await allow("203.0.113.7");
  console.log(`request ${i}: ${allowed ? "allowed" : "refused, 429"}`);
}
await redis.close();
