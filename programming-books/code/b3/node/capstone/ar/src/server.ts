import { Redis } from "ioredis";
import { buildApp } from "./app.ts";
import { config } from "./config.ts";
import { connect } from "./db.ts";

// جذر التركيب: الملف الوحيد الذي ينشئ الاتصالات
const db = connect();
const redis = new Redis(config.REDIS_URL, { maxRetriesPerRequest: 1 });
const app = await buildApp({ db, redis });
await app.listen({ host: "0.0.0.0", port: config.PORT });

// عند SIGTERM: توقّف عن قبول الطلبات، وأنهِ الجارية، ثم أغلق الاتصالات
process.once("SIGTERM", async () => {
  await app.close();
  await db.destroy();
  await redis.quit();
});
