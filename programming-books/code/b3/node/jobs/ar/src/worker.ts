import { Worker } from "bullmq";
import { sendMail } from "./mailer.ts";
import { type Confirmation, connection, mail } from "./queue.ts";

const start = Date.now();
const at = () => `${((Date.now() - start) / 1000).toFixed(1)}s`.padStart(5);

const worker = new Worker<Confirmation>(
  "mail",
  // العمل نفسه: يُستدعى مرة لكل مهمة، وربما مرة أخرى إن فشل
  async (job) => {
    const { orderId, email } = job.data;
    console.log(
      `${at()} إرسال تأكيد الطلب ${orderId} (المحاولة ${job.attemptsMade + 1})`,
    );
    await sendMail(orderId, email);
  },
  // مهمتان على الأكثر في الوقت نفسه في هذه العملية
  { connection, concurrency: 2 },
);

worker.on("completed", (job) => console.log(`${at()} ${job.id} أُرسل`));
worker.on("failed", (job, error) => {
  const final = job && job.attemptsMade >= (job.opts.attempts ?? 1);
  console.log(`${at()} ${job?.id} فشلت: ${error.message}`);
  if (final || error.name === "UnrecoverableError") {
    console.log(`${at()} ${job?.id} توقف؛ المحاولات: ${job?.attemptsMade}`);
  }
});

// لهذا العرض: توقف حين لا يبقى شيء
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

// أنهِ المهام التي في يدك قبل الخروج، عند Ctrl+C أو النشر
for (const signal of ["SIGINT", "SIGTERM"]) {
  process.once(signal, async () => {
    await Promise.all([worker.close(), mail.close()]);
    await connection.quit();
  });
}
