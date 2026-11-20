import { createClient } from "redis";

const LIMIT = 5;
const WINDOW = 10; // seconds

// one counter per client; the first request starts a 10-second window
async function allow(redis: ReturnType<typeof createClient>, client: string) {
  const key = `rate:${client}`;
  // MULTI/EXEC: both commands run together, nothing in between
  const [count] = await redis.multi().incr(key).expire(key, WINDOW, "NX").exec();
  return { allowed: Number(count) <= LIMIT, count: Number(count), key };
}

// two servers, two connections, one Redis: the limit is shared
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
    ? `allowed (${count} of ${LIMIT})`
    : `refused, 429, try again in ${await redis.ttl(key)} s`;
  console.log(`request ${i} via server ${name}: ${answer}`);
}
await servers.A.close();
await servers.B.close();
