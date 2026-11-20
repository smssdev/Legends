import { connection, mail } from "../src/queue.ts";

for (const job of await mail.getFailed()) {
  console.log(job.id, job.attemptsMade, job.failedReason);
}
await mail.close();
await connection.quit();
