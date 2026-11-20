import { createClient } from "redis";

const LIMIT = 5;
const WINDOW = 10; // seconds

// عداد لكل عميل؛ وأول طلب يبدأ نافذة من 10 ثوانٍ
async function allow(redis: ReturnType<typeof createClient>, client: string) {
  const key = `rate:${client}`;
  // MULTI/EXEC: الأمران ينفذان معاً، ولا شيء بينهما
  const [count] = await redis.multi().incr(key).expire(key, WINDOW, "NX").exec();
  return { allowed: Number(count) <= LIMIT, count: Number(count), key };
}

// خادمان، واتصالان، وRedis واحد: الحد مشترك
const servers = {
  A: await createClient({ url: "redis://localhost:6379" }).connect(),
  B: await createClient({ url: "redis://localhost:6379" }).connect(),
};
await servers.A.del("rate:203.0.113.7");
for (let i = 1; i <= 8; i++) {
  const name = i % 2 === 1 ? "A" : "B";
  const redis = servers[name];
  const { allowed, count, key } = await allow(redis, "203.0.113.7");
  const answer = allowed
    ? `مسموح (${count} من ${LIMIT})`
    : `مرفوض، 429، حاول بعد ${await redis.ttl(key)} ث`;
  console.log(`الطلب ${i} عبر الخادم ${name}: ${answer}`);
}
await servers.A.close();
await servers.B.close();
