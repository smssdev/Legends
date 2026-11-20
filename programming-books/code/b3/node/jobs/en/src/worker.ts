import { Worker } from "bullmq";
import { sendMail } from "./mailer.ts";
import { type Confirmation, connection, mail } from "./queue.ts";

const start = Date.now();
const at = () => `${((Date.now() - start) / 1000).toFixed(1)}s`.padStart(5);

const worker = new Worker<Confirmation>(
  "mail",
  // the work itself: called once per job, maybe again if it fails
  async (job) => {
    const { orderId, email } = job.data;
    console.log(
      `${at()} sending the confirmation for order ${orderId} (attempt ${job.attemptsMade + 1})`,
    );
    await sendMail(orderId, email);
  },
  // at most two jobs at the same time in this process
  { connection, concurrency: 2 },
);

worker.on("completed", (job) => console.log(`${at()} ${job.id} sent`));
worker.on("failed", (job, error) => {
  const final = job && job.attemptsMade >= (job.opts.attempts ?? 1);
  console.log(`${at()} ${job?.id} failed: ${error.message}`);
  if (final || error.name === "UnrecoverableError") {
    console.log(`${at()} ${job?.id} gave up; attempts made: ${job?.attemptsMade}`);
  }
});

// for this demo: stop when nothing is left to do
if (process.argv.includes("--until-empty")) {
  const timer = setInterval(async () => {
    const counts = await mail.getJobCounts("wait", "active", "delayed");
    if (Object.values(counts).every((n) => n === 0)) {
      clearInterval(timer);
      await Promise.all([worker.close(), mail.close()]);
      await connection.quit();
    }
  }, 200);
}

// finish the jobs in hand before exiting, on Ctrl+C or a deploy
for (const signal of ["SIGINT", "SIGTERM"]) {
  process.once(signal, async () => {
    await Promise.all([worker.close(), mail.close()]);
    await connection.quit();
  });
}
