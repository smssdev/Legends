import { connection, mail } from "../src/queue.ts";

// التمرين 4: أعطِ المهام الفاشلة فرصة أخرى بعد إصلاح السبب
for (const job of await mail.getFailed()) {
  await job.updateData({ ...job.data, email: "karim@example.com" });
  await job.retry();
  console.log(job.id, "أُعيدت");
}
await mail.close();
await connection.quit();
