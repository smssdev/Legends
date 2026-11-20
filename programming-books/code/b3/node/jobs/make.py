"""Writes the examples of Book 3 (Node edition), the chapter "Background Jobs and Queues".
Run: python3 make.py   (Redis through code/b3/bin/redis-start)

BullMQ on Redis: an order confirmation queued in milliseconds and sent later by a separate worker process,
the same order queued twice and kept once (a job id), a flaky mail service retried with growing pauses, a job
that fails every attempt and waits in the failed list until someone retries it, two jobs at a time, and a job
scheduler for a daily report. What the terminal showed is saved as transcripts (*.sh).
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent.parent
sys.path.insert(0, str(B3))
from rec import CLEAN, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_conn="one connection setting for the queue and the worker",
        w_c_options="what every confirmation job gets unless it says otherwise",
        w_c_id="the job id is the order id: queuing the same order twice keeps one job",
        w_c_attempts="up to 3 attempts, waiting 1, then 2 seconds between them",
        w_c_keep="finished jobs are kept for an hour (to look at), failed ones for a week",
        w_c_work="the work itself: called once per job, maybe again if it fails",
        w_c_flaky="a mail service that fails the first two times for order 1003",
        w_c_invalid="an address that can never work: no point trying forever",
        w_c_concurrency="at most two jobs at the same time in this process",
        w_c_drain="for this demo: stop when nothing is left to do",
        w_c_shutdown="finish the jobs in hand before exiting, on Ctrl+C or a deploy",
        w_c_schedule="a job scheduler: BullMQ creates the job at every matching time",
        w_c_retry="exercise 4: give failed jobs another chance after the cause is fixed",
        w_d_queued="queued in", w_d_again="queued again; jobs waiting:", w_d_job="job",
        w_d_sending="sending the confirmation for order", w_d_sent="sent", w_d_try="attempt",
        w_d_failed="failed", w_d_gave_up="gave up; attempts made:", w_d_attempts="attempts",
        w_d_waiting="jobs waiting:", w_d_next="next run:", w_d_retried="retried",
        w_d_mail_down="mail service unavailable", w_d_bad_address="invalid address",
        w_s_enqueue="The shop queues four confirmations (and one twice)",
        w_s_waiting="Nobody is working yet: the jobs wait in Redis",
        w_s_worker="A worker starts and does them",
        w_s_failed="What is left in the failed list",
        w_s_schedule="A report every morning at 6, Cairo time",
        w_s_retry="The address is fixed; retry the failed job",
    ),
    "ar": dict(
        w_c_conn="إعداد اتصال واحد للطابور والعامل",
        w_c_options="ما تأخذه كل مهمة تأكيد ما لم تقل غير ذلك",
        w_c_id="رقم المهمة هو رقم الطلب: وضع الطلب نفسه في الطابور مرتين يُبقي مهمة واحدة",
        w_c_attempts="حتى 3 محاولات، بانتظار ثانية ثم ثانيتين بينها",
        w_c_keep="المهام المنتهية تُحفظ ساعة (للاطلاع عليها)، والفاشلة أسبوعاً",
        w_c_work="العمل نفسه: يُستدعى مرة لكل مهمة، وربما مرة أخرى إن فشل",
        w_c_flaky="خدمة بريد تفشل أول مرتين للطلب 1003",
        w_c_invalid="عنوان لا يمكن أن ينجح أبداً: لا فائدة من المحاولة إلى الأبد",
        w_c_concurrency="مهمتان على الأكثر في الوقت نفسه في هذه العملية",
        w_c_drain="لهذا العرض: توقف حين لا يبقى شيء",
        w_c_shutdown="أنهِ المهام التي في يدك قبل الخروج، عند Ctrl+C أو النشر",
        w_c_schedule="مجدول مهام: ينشئ BullMQ المهمة في كل وقت مطابق",
        w_c_retry="التمرين 4: أعطِ المهام الفاشلة فرصة أخرى بعد إصلاح السبب",
        w_d_queued="في الطابور خلال", w_d_again="في الطابور مرة أخرى؛ المهام المنتظرة:", w_d_job="المهمة",
        w_d_sending="إرسال تأكيد الطلب", w_d_sent="أُرسل", w_d_try="المحاولة",
        w_d_failed="فشلت", w_d_gave_up="توقف؛ المحاولات:", w_d_attempts="محاولات",
        w_d_waiting="المهام المنتظرة:", w_d_next="التشغيل التالي:", w_d_retried="أُعيدت",
        w_d_mail_down="خدمة البريد غير متاحة", w_d_bad_address="عنوان غير صالح",
        w_s_enqueue="المتجر يضع أربعة تأكيدات في الطابور (وواحداً مرتين)",
        w_s_waiting="لا أحد يعمل بعد: المهام تنتظر في Redis",
        w_s_worker="عامل يبدأ وينجزها",
        w_s_failed="ما بقي في قائمة الفاشلة",
        w_s_schedule="تقرير كل صباح في السادسة بتوقيت القاهرة",
        w_s_retry="أُصلح العنوان؛ أعد المهمة الفاشلة",
    ),
}

FILES = {
    "package.json": '''{
  "name": "bit-shop-jobs",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "worker": "node src/worker.ts",
    "check": "tsc"
  },
  "dependencies": {
    "bullmq": "^6.7.0",
    "ioredis": "^6.0.0"
  },
  "devDependencies": {
    "@types/node": "^22.20.5",
    "typescript": "^7.0.2"
  }
}
''',
    "tsconfig.json": '''{
  "compilerOptions": {
    "target": "es2024",
    "module": "nodenext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "erasableSyntaxOnly": true,
    "verbatimModuleSyntax": true,
    "types": ["node"]
  },
  "include": ["src", "demos"]
}
''',
    "src/queue.ts": '''import { Queue } from "bullmq";
import { Redis } from "ioredis";

// {w_c_conn}
export const connection = new Redis("redis://localhost:6379", {
  maxRetriesPerRequest: null,
});

export type Confirmation = { orderId: number; email: string };

export const mail = new Queue<Confirmation>("mail", {
  connection,
  // {w_c_options}
  defaultJobOptions: {
    // {w_c_attempts}
    attempts: 3,
    backoff: { type: "exponential", delay: 1000 },
    // {w_c_keep}
    removeOnComplete: { age: 3600 },
    removeOnFail: { age: 7 * 24 * 3600 },
  },
});

export function queueConfirmation(orderId: number, email: string) {
  // {w_c_id}
  return mail.add("confirmation", { orderId, email }, { jobId: `order-${orderId}` });
}
''',
    "src/mailer.ts": '''import { UnrecoverableError } from "bullmq";

const attempts = new Map<number, number>();

// A stand-in for a real mail service, with its bad days.
export async function sendMail(orderId: number, email: string) {
  await new Promise((resolve) => setTimeout(resolve, 300));
  const n = (attempts.get(orderId) ?? 0) + 1;
  attempts.set(orderId, n);
  // {w_c_flaky}
  if (orderId === 1003 && n <= 2) throw new Error("{w_d_mail_down}");
  // {w_c_invalid}
  if (!email.includes("@")) throw new UnrecoverableError(`{w_d_bad_address}: ${email}`);
}
''',
    "src/worker.ts": '''import { Worker } from "bullmq";
import { sendMail } from "./mailer.ts";
import { type Confirmation, connection, mail } from "./queue.ts";

const start = Date.now();
const at = () => `${((Date.now() - start) / 1000).toFixed(1)}s`.padStart(5);

const worker = new Worker<Confirmation>(
  "mail",
  // {w_c_work}
  async (job) => {
    const { orderId, email } = job.data;
    console.log(`${at()} {w_d_sending} ${orderId} ({w_d_try} ${job.attemptsMade + 1})`);
    await sendMail(orderId, email);
  },
  // {w_c_concurrency}
  { connection, concurrency: 2 },
);

worker.on("completed", (job) => console.log(`${at()} ${job.id} {w_d_sent}`));
worker.on("failed", (job, error) => {
  const final = job && job.attemptsMade >= (job.opts.attempts ?? 1);
  console.log(`${at()} ${job?.id} {w_d_failed}: ${error.message}`);
  if (final || error.name === "UnrecoverableError") {
    console.log(`${at()} ${job?.id} {w_d_gave_up} ${job?.attemptsMade}`);
  }
});

// {w_c_drain}
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

// {w_c_shutdown}
for (const signal of ["SIGINT", "SIGTERM"]) {
  process.once(signal, async () => {
    await Promise.all([worker.close(), mail.close()]);
    await connection.quit();
  });
}
''',
    "demos/enqueue.ts": '''import { connection, mail, queueConfirmation } from "../src/queue.ts";

const orders = [
  [1001, "sara@example.com"],
  [1002, "omar@example.com"],
  [1003, "lina@example.com"],
  [1004, "karim-at-example.com"],
] as const;

for (const [orderId, email] of orders) {
  const start = performance.now();
  const job = await queueConfirmation(orderId, email);
  const ms = (performance.now() - start).toFixed(1);
  console.log(`{w_d_job} ${job.id} {w_d_queued} ${ms} ms`);
}
const again = await queueConfirmation(1001, "sara@example.com");
console.log(`{w_d_job} ${again.id} {w_d_again} ${await mail.count()}`);
await mail.close();
await connection.quit();
''',
    "demos/failed.ts": '''import { connection, mail } from "../src/queue.ts";

for (const job of await mail.getFailed()) {
  console.log(job.id, job.attemptsMade, job.failedReason);
}
await mail.close();
await connection.quit();
''',
    "demos/retry.ts": '''import { connection, mail } from "../src/queue.ts";

// {w_c_retry}
for (const job of await mail.getFailed()) {
  await job.updateData({ ...job.data, email: "karim@example.com" });
  await job.retry();
  console.log(job.id, "{w_d_retried}");
}
await mail.close();
await connection.quit();
''',
    "demos/schedule.ts": '''import { Queue } from "bullmq";
import { connection } from "../src/queue.ts";

const reports = new Queue("reports", { connection });
// {w_c_schedule}
await reports.upsertJobScheduler(
  "daily-sales",
  { pattern: "0 6 * * *", tz: "Africa/Cairo" },
  { name: "sales-report", data: { period: "yesterday" } },
);
for (const s of await reports.getJobSchedulers()) {
  console.log(s.key, s.pattern, s.tz, "{w_d_next}", new Date(s.next ?? 0).toISOString());
}
await reports.close();
await connection.quit();
''',
}


def record(folder, t):
    subprocess.run(["redis-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("npx tsc")
    s.lines.clear()
    s.note(t["w_s_enqueue"])
    s.run("node demos/enqueue.ts")
    s.note(t["w_s_waiting"])
    s.run("redis-cli LLEN bull:mail:wait")
    s.save(folder / "enqueue.sh")
    s.note(t["w_s_worker"])
    s.run("node src/worker.ts --until-empty")
    s.save(folder / "worker.sh")
    s.note(t["w_s_failed"])
    s.run("node demos/failed.ts")
    s.save(folder / "failed.sh")
    s.note(t["w_s_schedule"])
    s.run("node demos/schedule.ts")
    s.save(folder / "schedule.sh")
    s.note(t["w_s_retry"])
    s.run("node demos/retry.ts")
    s.run("node src/worker.ts --until-empty")
    s.save(folder / "answers.sh")


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    os.symlink(B3 / "node_modules", folder / "node_modules")
    subprocess.run(["npx", "prettier", "--print-width", "84", "--write", "src", "demos"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
