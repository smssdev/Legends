"""Writes the examples of Book 4, chapter "Payments, Email and Files", in English and Arabic.
Run: python3 make.py   (after `npm ci` in code/b4; PostgreSQL through code/b3/bin/pg-start; Mailpit and
SeaweedFS in Docker)

Three integrations of Bit Booking, each with the pattern that works with any provider:
- payments: a deposit through a payment provider. provider.ts stands in for one (checkout sessions and
  signed webhooks, the shape of Stripe or Paymob); the webhook is verified on its raw bytes, recorded once
  by its event id, and applied in one transaction with an outbox row;
- email: the outbox is sent over real SMTP to Mailpit, a local mail catcher, and read back from its API;
- files: a business logo goes straight from the browser to S3-compatible storage (SeaweedFS) with a
  presigned URL, and the server checks the stored object before accepting it.
The services' logic lives in src/ (the same functions would sit behind Bit Booking's route handlers); a small
Fastify server exposes them. Transcripts are *.sh.
"""
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_salon="Bit Hair Studio", w_mona="Mona",
        w_subject="Your deposit is received", w_body="Your booking on 1 December at 10:00 is confirmed. Deposit: {amount} EGP.",
        w_c_env="every key and secret comes from the environment; none is in the code",
        w_c_pending="the payment exists before the customer pays: the webhook only completes it",
        w_c_raw="the signature covers the exact bytes sent: read the body as text, parse it after checking",
        w_c_sign="the signature: HMAC-SHA256 of the timestamp and the body, with the shared secret",
        w_c_old="an old timestamp is a replay of a recorded request",
        w_c_once="providers deliver at least once: the event id makes the second delivery a no-op",
        w_c_apply="all or nothing: the payment, the booking and the email to send",
        w_c_outbox="the email is a row in the same transaction; the mailer sends it after the commit",
        w_c_mailer="the mailer: send what the outbox holds, mark it sent",
        w_c_presign="the browser uploads straight to storage; the server only signs a short-lived URL",
        w_c_key="the key is chosen by the server: the client cannot write anywhere else",
        w_c_verify="trust, then verify: check what was really stored before using it",
        w_c_fake="a stand-in for a payment provider: checkout sessions and signed webhooks",
        w_c_deliver="the provider calls the shop's webhook, signed with the shared secret",
        w_m_bad_sig="Invalid signature", w_m_too_big="Logo too large", w_m_type="Logo must be PNG, JPEG or WebP",
        w_m_none="Not found",
        w_s_deposit="The customer asks to pay a 50 EGP deposit", w_s_pay="She pays on the provider's page",
        w_s_rows="The payment and the booking", w_s_again="The provider delivers the same event again",
        w_s_forged="Someone forges a webhook", w_s_mail="The mailer sends the outbox; the mail catcher received it",
        w_s_logo="The owner uploads a logo", w_s_put="The browser sends the file straight to storage",
        w_s_ok="The server checks what was stored", w_s_big="Someone uploads 3 MB with a URL signed for a logo",
        w_s_type="A different file type than the one signed",
    ),
    "ar": dict(
        w_salon="صالون بِت", w_mona="منى",
        w_subject="وصل عربونك", w_body="تأكد حجزك يوم 1 ديسمبر الساعة 10:00. العربون: {amount} جنيهاً.",
        w_c_env="كل مفتاح وسر يأتي من البيئة؛ ولا شيء منها في الكود",
        w_c_pending="الدفعة موجودة قبل أن يدفع الزبون: الـ webhook يكملها فقط",
        w_c_raw="التوقيع يغطي البايتات المرسلة بالضبط: اقرأ الجسم نصاً، وحلّله بعد الفحص",
        w_c_sign="التوقيع: HMAC-SHA256 للطابع الزمني والجسم، بالسر المشترك",
        w_c_old="الطابع الزمني القديم إعادة لطلب مسجَّل",
        w_c_once="المزوّدون يسلّمون مرة على الأقل: رقم الحدث يجعل التسليم الثاني بلا أثر",
        w_c_apply="الكل أو لا شيء: الدفعة والحجز والبريد المطلوب إرساله",
        w_c_outbox="البريد صف في المعاملة نفسها؛ والمرسِل يرسله بعد الاعتماد",
        w_c_mailer="المرسِل: أرسل ما في الصندوق الصادر، وعلّمه مُرسلاً",
        w_c_presign="المتصفح يرفع مباشرة إلى المخزن؛ والخادم يوقّع رابطاً قصير العمر فقط",
        w_c_key="الخادم يختار المفتاح: لا يستطيع العميل أن يكتب في أي مكان آخر",
        w_c_verify="ثق ثم تحقق: افحص ما خُزّن فعلاً قبل أن تستعمله",
        w_c_fake="بديل لمزوّد دفع: جلسات دفع وwebhooks موقَّعة",
        w_c_deliver="ينادي المزوّد الـ webhook الخاص بالمتجر، موقَّعاً بالسر المشترك",
        w_m_bad_sig="توقيع غير صالح", w_m_too_big="الشعار كبير جداً", w_m_type="يجب أن يكون الشعار PNG أو JPEG أو WebP",
        w_m_none="غير موجود",
        w_s_deposit="الزبونة تطلب دفع عربون 50 جنيهاً", w_s_pay="تدفع في صفحة المزوّد",
        w_s_rows="الدفعة والحجز", w_s_again="المزوّد يسلّم الحدث نفسه ثانية",
        w_s_forged="أحدهم يزوّر webhook", w_s_mail="المرسِل يرسل الصندوق الصادر؛ وصلت الرسالة إلى ملتقط البريد",
        w_s_logo="صاحبة العمل ترفع شعاراً", w_s_put="المتصفح يرسل الملف مباشرة إلى المخزن",
        w_s_ok="الخادم يفحص ما خُزّن", w_s_big="أحدهم يرفع 3 MB برابط موقَّع لشعار",
        w_s_type="نوع ملف غير الذي وُقّع",
    ),
}

FILES = {
    ".env": '''DATABASE_URL=postgres://bit:secret@localhost:5432/shop
PROVIDER_URL=http://localhost:4000
PROVIDER_KEY=sk_test_51bitbooking
WEBHOOK_SECRET=whsec_7d1c9e2b4a
SMTP_URL=smtp://localhost:1025
S3_ENDPOINT=http://localhost:8333
S3_BUCKET=bit-booking
S3_KEY=bitkey
S3_SECRET=bitsecret
''',
    "package.json": '''{
  "name": "bit-booking-outside",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node --env-file=.env src/server.ts",
    "provider": "node --env-file=.env provider.ts",
    "mailer": "node --env-file=.env src/mailer.ts"
  }
}
''',
    "tsconfig.json": '''{
  "compilerOptions": {
    "target": "es2023",
    "module": "nodenext",
    "strict": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "erasableSyntaxOnly": true,
    "verbatimModuleSyntax": true,
    "skipLibCheck": true,
    "types": ["node"]
  },
  "include": ["src", "provider.ts"]
}
''',
    "schema.sql": '''CREATE TABLE businesses (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  logo_key text
);
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses (id),
  email text NOT NULL,
  status text NOT NULL CHECK (status IN ('awaiting_deposit', 'confirmed', 'cancelled'))
);
CREATE TABLE payments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  booking_id bigint NOT NULL REFERENCES bookings (id),
  amount integer NOT NULL CHECK (amount > 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed')),
  checkout_id text UNIQUE
);
CREATE TABLE webhook_events (
  id text PRIMARY KEY,
  received_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE outbox (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  recipient text NOT NULL,
  subject text NOT NULL,
  body text NOT NULL,
  sent_at timestamptz
);
INSERT INTO businesses (name) VALUES ('{w_salon}');
INSERT INTO bookings (business_id, email, status) VALUES (1, 'sara@example.com', 'awaiting_deposit');
''',
    "src/config.ts": '''// {w_c_env}
const need = (name: string) => {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is not set`);
  return value;
};

export const config = {
  databaseUrl: need("DATABASE_URL"),
  providerUrl: need("PROVIDER_URL"),
  providerKey: need("PROVIDER_KEY"),
  webhookSecret: need("WEBHOOK_SECRET"),
  smtpUrl: need("SMTP_URL"),
  s3: {
    endpoint: need("S3_ENDPOINT"),
    bucket: need("S3_BUCKET"),
    key: need("S3_KEY"),
    secret: need("S3_SECRET"),
  },
};
''',
    "src/db.ts": '''import pg from "pg";
import { config } from "./config.ts";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));
export const pool = new pg.Pool({ connectionString: config.databaseUrl });
''',
    "src/payments.ts": '''import { createHmac, timingSafeEqual } from "node:crypto";
import { config } from "./config.ts";
import { pool } from "./db.ts";

const DEPOSIT = 5000; // piastres

export async function startDeposit(bookingId: number) {
  // {w_c_pending}
  const { rows } = await pool.query<{ id: number }>(
    `INSERT INTO payments (booking_id, amount)
     SELECT id, $2 FROM bookings WHERE id = $1 AND status = 'awaiting_deposit'
     RETURNING id`,
    [bookingId, DEPOSIT],
  );
  const payment = rows[0];
  if (!payment) return null;
  const res = await fetch(`${config.providerUrl}/checkouts`, {
    method: "POST",
    headers: { authorization: `Bearer ${config.providerKey}`, "content-type": "application/json" },
    body: JSON.stringify({ amount: DEPOSIT, currency: "EGP", reference: String(payment.id) }),
  });
  if (!res.ok) throw new Error(`provider answered ${res.status}`);
  const checkout = (await res.json()) as { id: string; url: string };
  await pool.query("UPDATE payments SET checkout_id = $1 WHERE id = $2", [checkout.id, payment.id]);
  return checkout.url;
}

// {w_c_sign}
export function verifySignature(header: string, body: string, now = Date.now()) {
  const parts = Object.fromEntries(header.split(",").map((p) => p.split("=") as [string, string]));
  const t = Number(parts.t);
  // {w_c_old}
  if (!Number.isInteger(t) || Math.abs(now / 1000 - t) > 300) return false;
  const expected = createHmac("sha256", config.webhookSecret).update(`${t}.${body}`).digest();
  const given = Buffer.from(parts.v1 ?? "", "hex");
  return given.length === expected.length && timingSafeEqual(given, expected);
}

type Event = { id: string; type: string; data: { checkout_id: string } };

export async function applyEvent(event: Event): Promise<"applied" | "duplicate" | "ignored"> {
  const client = await pool.connect();
  try {
    // {w_c_apply}
    await client.query("BEGIN");
    // {w_c_once}
    const fresh = await client.query(
      "INSERT INTO webhook_events (id) VALUES ($1) ON CONFLICT DO NOTHING",
      [event.id],
    );
    if (fresh.rowCount === 0) {
      await client.query("ROLLBACK");
      return "duplicate";
    }
    if (event.type !== "checkout.paid") {
      await client.query("COMMIT");
      return "ignored";
    }
    const { rows } = await client.query<{ booking_id: number; amount: number; email: string }>(
      `UPDATE payments p SET status = 'paid'
         FROM bookings b
        WHERE p.checkout_id = $1 AND p.status = 'pending' AND b.id = p.booking_id
        RETURNING p.booking_id, p.amount, b.email`,
      [event.data.checkout_id],
    );
    const paid = rows[0];
    if (paid) {
      await client.query("UPDATE bookings SET status = 'confirmed' WHERE id = $1", [paid.booking_id]);
      // {w_c_outbox}
      await client.query(
        "INSERT INTO outbox (recipient, subject, body) VALUES ($1, $2, $3)",
        [paid.email, "{w_subject}", `{w_body}`.replace("{amount}", String(paid.amount / 100))],
      );
    }
    await client.query("COMMIT");
    return "applied";
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}
''',
    "src/mailer.ts": '''import nodemailer from "nodemailer";
import { config } from "./config.ts";
import { pool } from "./db.ts";

const transport = nodemailer.createTransport(config.smtpUrl);

// {w_c_mailer}
const { rows } = await pool.query<{ id: number; recipient: string; subject: string; body: string }>(
  "SELECT id, recipient, subject, body FROM outbox WHERE sent_at IS NULL ORDER BY id LIMIT 50",
);
for (const mail of rows) {
  await transport.sendMail({
    from: "Bit Booking <bookings@bitbooking.example>",
    to: mail.recipient,
    subject: mail.subject,
    text: mail.body,
    headers: { "X-Outbox-Id": String(mail.id) },
  });
  await pool.query("UPDATE outbox SET sent_at = now() WHERE id = $1", [mail.id]);
  console.log(`sent ${mail.id} to ${mail.recipient}`);
}
await pool.end();
''',
    "src/files.ts": '''import { randomUUID } from "node:crypto";
import {
  DeleteObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { config } from "./config.ts";
import { pool } from "./db.ts";

const s3 = new S3Client({
  endpoint: config.s3.endpoint,
  region: "us-east-1",
  forcePathStyle: true,
  credentials: { accessKeyId: config.s3.key, secretAccessKey: config.s3.secret },
});
const TYPES = { "image/png": "png", "image/jpeg": "jpg", "image/webp": "webp" } as const;
const MAX = 1024 * 1024;
type Type = keyof typeof TYPES;
export const isType = (t: string): t is Type => t in TYPES;

// {w_c_presign}
export async function logoUploadUrl(businessId: number, type: Type, size: number) {
  if (size > MAX) return { error: "too-big" as const };
  // {w_c_key}
  const key = `logos/${businessId}/${randomUUID()}.${TYPES[type]}`;
  const command = new PutObjectCommand({ Bucket: config.s3.bucket, Key: key, ContentType: type });
  const url = await getSignedUrl(s3, command, { expiresIn: 300 });
  return { key, url };
}

// {w_c_verify}
export async function acceptLogo(businessId: number, key: string) {
  if (!key.startsWith(`logos/${businessId}/`)) return "not-found";
  const head = await s3
    .send(new HeadObjectCommand({ Bucket: config.s3.bucket, Key: key }))
    .catch(() => null);
  if (!head) return "not-found";
  if ((head.ContentLength ?? 0) > MAX || !isType(head.ContentType ?? "")) {
    await s3.send(new DeleteObjectCommand({ Bucket: config.s3.bucket, Key: key }));
    return (head.ContentLength ?? 0) > MAX ? "too-big" : "bad-type";
  }
  await pool.query("UPDATE businesses SET logo_key = $1 WHERE id = $2", [key, businessId]);
  return "ok";
}
''',
    "src/server.ts": '''import Fastify from "fastify";
import { acceptLogo, isType, logoUploadUrl } from "./files.ts";
import { applyEvent, startDeposit, verifySignature } from "./payments.ts";

const app = Fastify();
const problem = (status: number, title: string) => ({ status, title });

app.post<{ Params: { id: string } }>("/bookings/:id/deposit", async (request, reply) => {
  const url = await startDeposit(Number(request.params.id));
  if (!url) return reply.code(404).send(problem(404, "{w_m_none}"));
  return { checkout_url: url };
});

await app.register(async (hooks) => {
  // {w_c_raw}
  hooks.removeContentTypeParser("application/json");
  hooks.addContentTypeParser("application/json", { parseAs: "string" }, (_req, body, done) =>
    done(null, body),
  );
  hooks.post("/webhooks/payments", async (request, reply) => {
    const body = request.body as string;
    const signature = String(request.headers["bit-signature"] ?? "");
    if (!verifySignature(signature, body)) {
      return reply.code(400).send(problem(400, "{w_m_bad_sig}"));
    }
    return { result: await applyEvent(JSON.parse(body)) };
  });
});

// in Bit Booking these two need requireUser(["owner"]) from Chapter 4; left out to keep the example short
app.post<{ Params: { id: string }; Body: { type: string; size: number } }>(
  "/businesses/:id/logo",
  async (request, reply) => {
    const { type, size } = request.body;
    if (!isType(type)) return reply.code(422).send(problem(422, "{w_m_type}"));
    const upload = await logoUploadUrl(Number(request.params.id), type, size);
    if ("error" in upload) return reply.code(422).send(problem(422, "{w_m_too_big}"));
    return upload;
  },
);

app.post<{ Params: { id: string }; Body: { key: string } }>(
  "/businesses/:id/logo/confirm",
  async (request, reply) => {
    const result = await acceptLogo(Number(request.params.id), request.body.key);
    if (result === "ok") return { logo: request.body.key };
    const [status, title] =
      result === "not-found" ? [404, "{w_m_none}"] : result === "too-big" ? [422, "{w_m_too_big}"] : [422, "{w_m_type}"];
    return reply.code(status).send(problem(status, title));
  },
);

await app.listen({ port: 3000 });
''',
    "provider.ts": '''import { createHmac, randomBytes } from "node:crypto";
import Fastify from "fastify";

// {w_c_fake}
const app = Fastify();
const checkouts = new Map<string, { amount: number; reference: string; event?: string }>();
const id = (prefix: string) => `${prefix}_${randomBytes(6).toString("hex")}`;

app.post<{ Body: { amount: number; reference: string } }>("/checkouts", async (request, reply) => {
  if (request.headers.authorization !== `Bearer ${process.env.PROVIDER_KEY}`) {
    return reply.code(401).send({ error: "invalid api key" });
  }
  const checkout = id("cs");
  checkouts.set(checkout, request.body);
  return { id: checkout, url: `http://localhost:4000/pay/${checkout}` };
});

// {w_c_deliver}
async function deliver(body: string) {
  const t = Math.floor(Date.now() / 1000);
  const v1 = createHmac("sha256", process.env.WEBHOOK_SECRET!).update(`${t}.${body}`).digest("hex");
  const res = await fetch("http://localhost:3000/webhooks/payments", {
    method: "POST",
    headers: { "content-type": "application/json", "bit-signature": `t=${t},v1=${v1}` },
    body,
  });
  return { status: res.status, answer: await res.json() };
}

app.post<{ Params: { checkout: string } }>("/pay/:checkout", async (request) => {
  const checkout = checkouts.get(request.params.checkout)!;
  checkout.event = JSON.stringify({
    id: id("evt"),
    type: "checkout.paid",
    data: { checkout_id: request.params.checkout },
  });
  return deliver(checkout.event);
});

app.post<{ Params: { checkout: string } }>("/pay/:checkout/redeliver", async (request) =>
  deliver(checkouts.get(request.params.checkout)!.event!),
);

await app.listen({ port: 4000 });
''',
}

S3_CONFIG = '''{
  "identities": [
    {
      "name": "bit",
      "credentials": [{ "accessKey": "bitkey", "secretKey": "bitsecret" }],
      "actions": ["Admin", "Read", "Write", "List", "Tagging"]
    }
  ]
}
'''


def services(folder):
    """Fresh PostgreSQL, Mailpit and SeaweedFS (S3), as on a developer's machine with Docker."""
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    for name in ("b4-mail", "b4-s3"):
        subprocess.run(["docker", "rm", "-f", name], capture_output=True)
    subprocess.run(["docker", "run", "-d", "--name", "b4-mail", "--network", "host", "axllent/mailpit:v1.27"],
                   check=True, capture_output=True)
    cfg = HERE / ".s3.json"
    cfg.write_text(S3_CONFIG)
    subprocess.run(["docker", "run", "-d", "--name", "b4-s3", "--network", "host", "-v", f"{cfg}:/s3.json:ro",
                    "chrislusf/seaweedfs:3.97", "server", "-s3", "-s3.port=8333", "-s3.config=/s3.json",
                    "-dir=/data", "-ip.bind=127.0.0.1", "-ip=127.0.0.1"], check=True, capture_output=True)
    for _ in range(120):
        ok = subprocess.run("curl -s -o /dev/null -w '%{http_code}' localhost:8333/ && "
                            "curl -s -o /dev/null localhost:8025/api/v1/info", shell=True,
                            capture_output=True, text=True)
        if ok.returncode == 0 and ok.stdout.strip() not in ("", "000"):
            break
        time.sleep(1)
    env = dict(CLEAN, AWS_ACCESS_KEY_ID="bitkey", AWS_SECRET_ACCESS_KEY="bitsecret")
    script = ("import { S3Client, CreateBucketCommand } from '@aws-sdk/client-s3';"
              "const s3 = new S3Client({ endpoint: 'http://localhost:8333', region: 'us-east-1', forcePathStyle: true });"
              "for (let i = 0; i < 30; i++) { try { await s3.send(new CreateBucketCommand({ Bucket: 'bit-booking' })); "
              "break; } catch (e) { await new Promise((r) => setTimeout(r, 1000)); } }")
    subprocess.run(["node", "--input-type=module", "-e", script], cwd=folder, env=env, check=True)


def record(folder, t):
    services(folder)
    s = Session(folder)
    s.run("psql shop -q -f schema.sql")
    s.run("npx tsc")
    s.lines.clear()
    base = "localhost:3000"
    with Server("node --env-file=.env provider.ts", folder, "http://localhost:4000/checkouts"), \
            Server("node --env-file=.env src/server.ts", folder, "http://localhost:3000/bookings/0/deposit"):
        s.note(t["w_s_deposit"])
        out = s.run(f"curl -s -X POST {base}/bookings/1/deposit | jq -c")
        checkout = out.split("/pay/")[1].split('"')[0]
        s.note(t["w_s_pay"])
        s.run(f"curl -s -X POST localhost:4000/pay/{checkout} | jq -c")
        s.note(t["w_s_rows"])
        s.run("psql shop -c 'SELECT p.id, p.amount, p.status AS payment, b.status AS booking "
              "FROM payments p JOIN bookings b ON b.id = p.booking_id'")
        s.note(t["w_s_again"])
        s.run(f"curl -s -X POST localhost:4000/pay/{checkout}/redeliver | jq -c")
        s.note(t["w_s_forged"])
        forged = '{"id":"evt_x","type":"checkout.paid","data":{"checkout_id":"cs_x"}}'
        s.run(f"curl -s {base}/webhooks/payments -H 'content-type: application/json' "
              f"-H 'bit-signature: t=1795190000,v1=00ff' -d '{forged}' | jq -c")
        s.save(folder / "payments.sh")

        s.note(t["w_s_mail"])
        s.run("npm run --silent mailer")
        s.run("curl -s localhost:8025/api/v1/messages | jq -c '.messages[] | {To: .To[0].Address, Subject}'")
        s.save(folder / "mail.sh")

        subprocess.run("head -c 2048 /dev/urandom > logo.png && head -c 3145728 /dev/urandom > big.png",
                       shell=True, cwd=folder, check=True)
        j = "-H 'content-type: application/json'"
        s.note(t["w_s_logo"])
        out = s.run(f"curl -s {base}/businesses/1/logo {j} -d '{{\"type\":\"image/png\",\"size\":2048}}' "
                    "| tee .upload | jq -c '{key, url: (.url[:60] + \"…\")}'")
        s.note(t["w_s_put"])
        s.run("curl -s -o /dev/null -w '%{http_code}\\n' -X PUT -H 'content-type: image/png' "
              "--upload-file logo.png \"$(jq -r .url .upload)\"",
              shown="curl -s -o /dev/null -w '%{http_code}\\n' -X PUT -H 'content-type: image/png' "
                    "--upload-file logo.png \"$URL\"")
        s.note(t["w_s_ok"])
        s.run(f"curl -s {base}/businesses/1/logo/confirm {j} -d \"{{\\\"key\\\":\\\"$(jq -r .key .upload)\\\"}}\" "
              "| jq -c", shown=f"curl -s {base}/businesses/1/logo/confirm {j} -d \"{{\\\"key\\\":\\\"$KEY\\\"}}\" | jq -c")
        s.note(t["w_s_big"])
        s.run(f"curl -s {base}/businesses/1/logo {j} -d '{{\"type\":\"image/png\",\"size\":2048}}' > .upload")
        s.run("curl -s -o /dev/null -w '%{http_code}\\n' -X PUT -H 'content-type: image/png' "
              "--upload-file big.png \"$(jq -r .url .upload)\"",
              shown="curl -s -o /dev/null -w '%{http_code}\\n' -X PUT -H 'content-type: image/png' "
                    "--upload-file big.png \"$URL\"")
        s.run(f"curl -s {base}/businesses/1/logo/confirm {j} -d \"{{\\\"key\\\":\\\"$(jq -r .key .upload)\\\"}}\" "
              "| jq -c", shown=f"curl -s {base}/businesses/1/logo/confirm {j} -d \"{{\\\"key\\\":\\\"$KEY\\\"}}\" | jq -c")
        s.note(t["w_s_type"])
        s.run("curl -s -o /dev/null -w '%{http_code}\\n' -X PUT -H 'content-type: text/html' "
              "--upload-file logo.png \"$(jq -r .url .upload)\"",
              shown="curl -s -o /dev/null -w '%{http_code}\\n' -X PUT -H 'content-type: text/html' "
                    "--upload-file logo.png \"$URL\"")
        s.run(f"curl -s {base}/businesses/1/logo/confirm {j} -d \"{{\\\"key\\\":\\\"$(jq -r .key .upload)\\\"}}\" "
              "| jq -c", shown=f"curl -s {base}/businesses/1/logo/confirm {j} -d \"{{\\\"key\\\":\\\"$KEY\\\"}}\" | jq -c")
        s.run("psql shop -c 'SELECT id, logo_key FROM businesses'")
        s.save(folder / "files.sh")
    for name in ("logo.png", "big.png", ".upload"):
        (folder / name).unlink(missing_ok=True)


try:
    for lang, t in T.items():
        if sys.argv[1:] and lang not in sys.argv[1:]:
            continue
        folder = HERE / lang
        if folder.exists():
            shutil.rmtree(folder)
        for name, text in FILES.items():
            path = folder / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(fill(text, t))
        os.symlink(B4 / "node_modules", folder / "node_modules")
        subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "84", "--write", "src",
                        "provider.ts"], cwd=folder, check=True, capture_output=True)
        record(folder, t)
        (folder / "node_modules").unlink()
        (folder / ".env").rename(folder / ".env.example")
        print("wrote", lang)
finally:
    for name in ("b4-mail", "b4-s3"):
        subprocess.run(["docker", "rm", "-f", name], capture_output=True)
    (HERE / ".s3.json").unlink(missing_ok=True)
