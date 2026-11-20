import { Queue } from "bullmq";
import { connection } from "../src/queue.ts";

const reports = new Queue("reports", { connection });
// a job scheduler: BullMQ creates the job at every matching time
await reports.upsertJobScheduler(
  "daily-sales",
  { pattern: "0 6 * * *", tz: "Africa/Cairo" },
  { name: "sales-report", data: { period: "yesterday" } },
);
for (const s of await reports.getJobSchedulers()) {
  console.log(
    s.key,
    s.pattern,
    s.tz,
    "next run:",
    new Date(s.next ?? 0).toISOString(),
  );
}
await reports.close();
await connection.quit();
