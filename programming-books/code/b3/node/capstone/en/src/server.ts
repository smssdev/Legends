import { Redis } from "ioredis";
import { buildApp } from "./app.ts";
import { config } from "./config.ts";
import { connect } from "./db.ts";

// the composition root: the only file that creates connections
const db = connect();
const redis = new Redis(config.REDIS_URL, { maxRetriesPerRequest: 1 });
const app = await buildApp({ db, redis });
await app.listen({ host: "0.0.0.0", port: config.PORT });

// on SIGTERM: stop taking requests, finish the ones in flight, then close the connections
process.once("SIGTERM", async () => {
  await app.close();
  await db.destroy();
  await redis.quit();
});
