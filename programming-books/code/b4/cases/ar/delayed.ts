import { createClient } from "redis";

const redis = await createClient({ url: process.env.REDIS_URL }).connect();
const now = Date.parse("2026-11-30T10:00:00Z");

// الدرجة هي وقت استحقاق المهمة: المجموعة مرتبة به دائماً
const jobs = [
  ["remind booking 41", now - 60_000],
  ["remind booking 42", now],
  ["remind booking 43", now + 3_600_000],
];
for (const [job, at] of jobs)
  await redis.zAdd("reminders", { score: at as number, value: job as string });
console.log("جُدولت:", await redis.zCard("reminders"));

// خذ مهمة مستحقة واحدة واحذفها في خطوة ذرية واحدة: لا يأخذ عاملان المهمة نفسها أبداً
const CLAIM = `
  local due = redis.call("ZRANGEBYSCORE", KEYS[1], "-inf", ARGV[1], "LIMIT", 0, 1)
  if #due == 0 then return false end
  redis.call("ZREM", KEYS[1], due[1])
  return due[1]
`;
for (;;) {
  const job = await redis.eval(CLAIM, {
    keys: ["reminders"],
    arguments: [String(now)],
  });
  if (!job) break;
  console.log("نُفذت:", job);
}
console.log("ما زالت تنتظر:", await redis.zRange("reminders", 0, -1));
await redis.quit();
