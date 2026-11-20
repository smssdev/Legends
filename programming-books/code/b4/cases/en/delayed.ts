import { createClient } from "redis";

const redis = await createClient({ url: process.env.REDIS_URL }).connect();
const now = Date.parse("2026-11-30T10:00:00Z");

// the score is the time the job is due: the set is always sorted by it
const jobs = [
  ["remind booking 41", now - 60_000],
  ["remind booking 42", now],
  ["remind booking 43", now + 3_600_000],
];
for (const [job, at] of jobs)
  await redis.zAdd("reminders", { score: at as number, value: job as string });
console.log("scheduled:", await redis.zCard("reminders"));

// take one due job and remove it in one atomic step: two workers never get the same job
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
  console.log("ran:", job);
}
console.log("still waiting:", await redis.zRange("reminders", 0, -1));
await redis.quit();
