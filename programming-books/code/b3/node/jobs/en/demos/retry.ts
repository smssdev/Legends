import { connection, mail } from "../src/queue.ts";

// exercise 4: give failed jobs another chance after the cause is fixed
for (const job of await mail.getFailed()) {
  await job.updateData({ ...job.data, email: "karim@example.com" });
  await job.retry();
  console.log(job.id, "retried");
}
await mail.close();
await connection.quit();
