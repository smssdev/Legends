"""Writes the examples of Book 4, chapter "Capstone: Ship a SaaS Product", in English and Arabic.
Run: python3 make.py   (after `npm ci` in code/b4; PostgreSQL through code/b3/bin/pg-start, so it needs Docker)

Bit Booking becomes a product that any salon can sign up for: one database for every salon, kept apart by
PostgreSQL's row-level security; a free plan with a monthly limit that holds even under concurrent requests;
a paid plan switched on by a signed, idempotent webhook from the payment provider; business numbers from SQL;
tests against the real database; and the launch checklist. Transcripts are *.sh.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_plans="what each plan allows; NULL means no limit; prices in piastres a month",
        w_c_tenant="every table that belongs to a salon carries salon_id",
        w_c_keys="API keys are stored as hashes, like passwords",
        w_c_events="each provider event is applied once: its id is the primary key",
        w_c_rls="row-level security: a query sees only the current salon's rows",
        w_c_unset="unset, or '' after a pooled connection used it: no rows at all",
        w_c_role="the app connects as app_user, which cannot bypass these policies",
        w_c_seed="two salons on the free plan, one already near its limit",
        w_c_with="every request runs in a transaction that sets its salon first",
        w_c_local="SET LOCAL: this transaction only; the pool never keeps it",
        w_c_lock="lock the salon's row: its concurrent bookings take turns here",
        w_c_limit="count this month's bookings under the lock, then decide",
        w_c_taken="23P01: the exclusion constraint; the slot was just taken",
        w_c_sign="the provider signs the exact body with our shared secret",
        w_c_safe="compare in constant time, so the answer's timing reveals nothing",
        w_c_once="a retried event inserts nothing and changes nothing",
        w_c_key="find the salon by the hash of its key; there is no other way in",
        w_c_admin="the tests prepare data as the owner, and check it as the app",
        w_c_race="ten at once, two left in the plan: exactly two may succeed",
        w_c_book="book <api key> <time>: Mona, 30 minutes, on 5 January 2027",
        w_c_deliver="deliver <event> [signature]: the payment provider; signs unless told",
        w_c_mrr="monthly recurring revenue: what the paid plans bring each month",
        w_limit="Free plan: 5 bookings a month. Upgrade to Pro for more.",
        w_taken="That time was just taken. Please choose another.",
        w_notfound="Not found", w_badsig="Invalid signature", w_nokey="Missing or unknown API key",
        w_t_isolation="a salon never sees another salon's bookings",
        w_t_unset="without a salon, a query returns nothing",
        w_t_race="the plan limit holds under concurrent bookings",
        w_t_webhook="a webhook delivered twice is applied once",
        w_s_book="Salon A books, until the free plan's limit",
        w_s_other="Salon B sees only its own bookings, and cannot open A's",
        w_s_upgrade="The provider says A paid; a forged or repeated event changes nothing",
        w_s_rls="What the database itself enforces",
        w_s_test="The rules that must never break, tested on the real database",
        w_s_metrics="The business, in numbers",
    ),
    "ar": dict(
        w_c_plans="ما يسمح به كل اشتراك؛ NULL تعني بلا حد؛ والأسعار بالقروش شهرياً",
        w_c_tenant="كل جدول يخص صالوناً يحمل salon_id",
        w_c_keys="مفاتيح الواجهة البرمجية تُخزن بصمات، ككلمات المرور",
        w_c_events="كل حدث من المزوّد يُطبَّق مرة واحدة: معرّفه هو المفتاح الأساسي",
        w_c_rls="أمان مستوى الصف: لا يرى الاستعلام إلا صفوف الصالون المضبوط لهذه المعاملة",
        w_c_unset="غير مضبوط، أو '' بعد أن استعمله اتصال المجموعة: لا صفوف إطلاقاً",
        w_c_role="يتصل التطبيق بـ app_user، الذي لا يستطيع تجاوز هذه السياسات",
        w_c_seed="صالونان على الاشتراك المجاني، أحدهما قرب حده",
        w_c_with="كل طلب يعمل في معاملة تضبط صالونه أولاً",
        w_c_local="SET LOCAL: لهذه المعاملة وحدها؛ لا تحتفظ بها المجموعة أبداً",
        w_c_lock="اقفل صف الصالون: تتناوب حجوزاته المتزامنة هنا",
        w_c_limit="عُدّ حجوزات هذا الشهر تحت القفل، ثم قرّر",
        w_c_taken="23P01: قيد الاستبعاد؛ الموعد حُجز للتو",
        w_c_sign="يوقّع المزوّد الجسم نفسه بالسر المشترك بيننا",
        w_c_safe="قارن في زمن ثابت، فلا يكشف توقيت الإجابة شيئاً",
        w_c_once="الحدث المعاد لا يُدخل شيئاً ولا يغيّر شيئاً",
        w_c_key="جد الصالون ببصمة مفتاحه؛ لا طريق آخر للدخول",
        w_c_admin="تجهّز الاختبارات البيانات بصفة المالك، وتفحصها بصفة التطبيق",
        w_c_race="عشرة معاً، وبقي في الاشتراك اثنان: ينجح اثنان بالضبط",
        w_c_book="book <api key> <time>: منى، 30 دقيقة، في 5 يناير 2027",
        w_c_deliver="deliver <event> [signature]: مزوّد الدفع؛ يوقّع ما لم يُعطَ توقيعاً",
        w_c_mrr="الإيراد الشهري المتكرر: ما تجلبه الاشتراكات المدفوعة كل شهر",
        w_limit="المجاني: 5 حجوزات في الشهر. رقِّ إلى Pro للمزيد.",
        w_taken="حُجز هذا الموعد للتو. اختر موعداً آخر من فضلك.",
        w_notfound="غير موجود", w_badsig="توقيع غير صالح", w_nokey="مفتاح الواجهة البرمجية مفقود أو غير معروف",
        w_t_isolation="لا يرى صالون حجوزات صالون آخر أبداً",
        w_t_unset="بلا صالون، لا يعيد الاستعلام شيئاً",
        w_t_race="حد الاشتراك يصمد أمام الحجوزات المتزامنة",
        w_t_webhook="الـwebhook المسلَّم مرتين يُطبَّق مرة",
        w_s_book="يحجز الصالون A، حتى حد الاشتراك المجاني",
        w_s_other="يرى الصالون B حجوزاته وحده، ولا يستطيع فتح حجوزات A",
        w_s_upgrade="يقول المزوّد إن A دفع؛ والحدث المزوّر أو المكرر لا يغيّر شيئاً",
        w_s_rls="ما تفرضه قاعدة البيانات نفسها",
        w_s_test="القواعد التي يجب ألا تنكسر أبداً، مختبرةً على قاعدة البيانات الحقيقية",
        w_s_metrics="العمل، بالأرقام",
    ),
}

SCHEMA = '''CREATE EXTENSION btree_gist;

-- {w_c_plans}
CREATE TABLE plans (
  id text PRIMARY KEY,
  monthly_bookings integer,
  price integer NOT NULL
);
INSERT INTO plans VALUES ('free', 5, 0), ('pro', NULL, 49900);

CREATE TABLE salons (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  plan text NOT NULL DEFAULT 'free' REFERENCES plans (id)
);
-- {w_c_keys}
CREATE TABLE api_keys (
  hash text PRIMARY KEY,
  salon_id bigint NOT NULL REFERENCES salons (id)
);
-- {w_c_tenant}
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  salon_id bigint NOT NULL REFERENCES salons (id),
  staff text NOT NULL,
  email text NOT NULL,
  during tstzrange NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT no_double_booking
    EXCLUDE USING gist (salon_id WITH =, staff WITH =, during WITH &&)
);
-- {w_c_events}
CREATE TABLE billing_events (
  id text PRIMARY KEY,
  received_at timestamptz NOT NULL DEFAULT now()
);

-- {w_c_rls}
ALTER TABLE salons ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
-- {w_c_unset}
CREATE FUNCTION current_salon() RETURNS bigint LANGUAGE sql STABLE
  RETURN nullif(current_setting('app.salon_id', true), '')::bigint;
CREATE POLICY own_salon ON salons
  USING (id = current_salon());
CREATE POLICY own_bookings ON bookings
  USING (salon_id = current_salon());

-- {w_c_role}
CREATE ROLE app_user LOGIN PASSWORD 'app';
GRANT SELECT, INSERT, UPDATE ON salons, bookings, billing_events
  TO app_user;
GRANT SELECT ON plans, api_keys TO app_user;

-- {w_c_seed}
INSERT INTO salons (name) VALUES ('Bit Hair Studio'), ('Nile Nails');
INSERT INTO api_keys VALUES
  (encode(sha256('key_a'), 'hex'), 1), (encode(sha256('key_b'), 'hex'), 2);
INSERT INTO bookings (salon_id, staff, email, during)
SELECT 1, 'Mona', 'guest@example.com', tstzrange(t, t + interval '30 min')
FROM generate_series(now() + interval '1 day', now() + interval '3 days',
                     interval '1 day') AS t;
INSERT INTO bookings (salon_id, staff, email, during) VALUES
  (2, 'Sara', 'nails@example.com', tstzrange(now(), now() + interval '1 h'));
'''

FILES = {
    "db.ts": '''import pg from "pg";

export const pool = new pg.Pool({
  connectionString: "postgres://app_user:app@localhost:5432/shop",
});

// {w_c_with}
export async function withSalon<T>(
  salonId: number,
  work: (db: pg.PoolClient) => Promise<T>,
): Promise<T> {
  const db = await pool.connect();
  try {
    await db.query("BEGIN");
    // {w_c_local}
    await db.query("SELECT set_config('app.salon_id', $1, true)", [String(salonId)]);
    const result = await work(db);
    await db.query("COMMIT");
    return result;
  } catch (error) {
    await db.query("ROLLBACK");
    throw error;
  } finally {
    db.release();
  }
}
''',
    "bookings.ts": '''import { withSalon } from "./db.ts";

export class Problem extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

type NewBooking = { staff: string; email: string; start: string; minutes: number };

export function book(salonId: number, b: NewBooking) {
  return withSalon(salonId, async (db) => {
    // {w_c_lock}
    const { rows } = await db.query(
      `SELECT p.monthly_bookings AS max FROM salons s
       JOIN plans p ON p.id = s.plan WHERE s.id = $1 FOR UPDATE OF s`,
      [salonId],
    );
    // {w_c_limit}
    const max: number | null = rows[0].max;
    if (max !== null) {
      const used = await db.query(
        `SELECT count(*)::int AS n FROM bookings
         WHERE created_at >= date_trunc('month', now())`,
      );
      if (used.rows[0].n >= max) throw new Problem(402, "{w_limit}");
    }
    const end = new Date(Date.parse(b.start) + b.minutes * 60_000);
    try {
      const inserted = await db.query(
        `INSERT INTO bookings (salon_id, staff, email, during)
         VALUES ($1, $2, $3, tstzrange($4, $5)) RETURNING id`,
        [salonId, b.staff, b.email, b.start, end],
      );
      return { id: inserted.rows[0].id as string };
    } catch (error) {
      // {w_c_taken}
      if ((error as { code?: string }).code === "23P01") throw new Problem(409, "{w_taken}");
      throw error;
    }
  });
}

export function list(salonId: number) {
  return withSalon(salonId, async (db) => {
    const { rows } = await db.query(
      "SELECT id, staff, email FROM bookings ORDER BY id",
    );
    return rows;
  });
}

export function one(salonId: number, id: string) {
  return withSalon(salonId, async (db) => {
    const { rows } = await db.query("SELECT id, staff, email FROM bookings WHERE id = $1", [id]);
    if (!rows[0]) throw new Problem(404, "{w_notfound}");
    return rows[0];
  });
}
''',
    "billing.ts": '''import { createHmac, timingSafeEqual } from "node:crypto";
import { withSalon } from "./db.ts";
import { Problem } from "./bookings.ts";

const secret = process.env.BILLING_SECRET ?? "whsec_test";

// {w_c_sign}
export function verify(body: string, header: string | undefined) {
  const expected = createHmac("sha256", secret).update(body).digest("hex");
  const given = String(header ?? "").replace("sha256=", "");
  // {w_c_safe}
  const ok =
    given.length === expected.length &&
    timingSafeEqual(Buffer.from(given), Buffer.from(expected));
  if (!ok) throw new Problem(401, "{w_badsig}");
}

type BillingEvent = { id: string; type: string; salon: number; plan: string };

export function apply(event: BillingEvent) {
  return withSalon(event.salon, async (db) => {
    // {w_c_once}
    const fresh = await db.query(
      `INSERT INTO billing_events (id) VALUES ($1)
       ON CONFLICT DO NOTHING`,
      [event.id],
    );
    if (fresh.rowCount === 0) return { applied: false };
    if (event.type === "subscription.updated") {
      const change = "UPDATE salons SET plan = $1 WHERE id = $2";
      await db.query(change, [event.plan, event.salon]);
    }
    return { applied: true };
  });
}
''',
    "server.ts": '''import { createHash } from "node:crypto";
import { createServer } from "node:http";
import { apply, verify } from "./billing.ts";
import { Problem, book, list, one } from "./bookings.ts";
import { pool } from "./db.ts";

// {w_c_key}
async function salonOf(key: string | string[] | undefined) {
  const hash = createHash("sha256").update(String(key ?? "")).digest("hex");
  const { rows } = await pool.query("SELECT salon_id FROM api_keys WHERE hash = $1", [hash]);
  if (!rows[0]) throw new Problem(401, "{w_nokey}");
  return Number(rows[0].salon_id);
}

createServer(async (request, response) => {
  let body = "";
  for await (const chunk of request) body += chunk;
  const send = (status: number, data: unknown) =>
    response.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(data));
  try {
    const url = request.url ?? "";
    if (url === "/webhooks/billing") {
      verify(body, request.headers["x-signature"] as string | undefined);
      return send(200, await apply(JSON.parse(body)));
    }
    const salon = await salonOf(request.headers["x-api-key"]);
    if (request.method === "POST" && url === "/bookings")
      return send(201, await book(salon, JSON.parse(body)));
    if (url === "/bookings") return send(200, await list(salon));
    if (url.startsWith("/bookings/")) return send(200, await one(salon, url.slice(10)));
    send(404, { message: "{w_notfound}" });
  } catch (error) {
    if (error instanceof Problem) return send(error.status, { message: error.message });
    console.error(error);
    send(500, { message: "Server error" });
  }
}).listen(4000);
''',
    "app.test.ts": '''import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import pg from "pg";
import { apply } from "./billing.ts";
import { book, list } from "./bookings.ts";
import { pool, withSalon } from "./db.ts";

// {w_c_admin}
const owner = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop" });
let a = 0;
let b = 0;
before(async () => {
  const add = "INSERT INTO salons (name) VALUES ($1) RETURNING id";
  a = Number((await owner.query(add, ["Test A"])).rows[0].id);
  b = Number((await owner.query(add, ["Test B"])).rows[0].id);
});
after(() => Promise.all([owner.end(), pool.end()]));

const at = (day: number, hour: number) => `2027-01-${day}T${hour}:00:00Z`;

test("{w_t_isolation}", async () => {
  await book(a, { staff: "Mona", email: "x@example.com", start: at(10, 10), minutes: 30 });
  const seen = await list(b);
  assert.equal(seen.length, 0);
});

test("{w_t_unset}", async () => {
  const { rows } = await pool.query("SELECT count(*)::int AS n FROM bookings");
  assert.equal(rows[0].n, 0);
});

test("{w_t_race}", async () => {
  await owner.query(
    `INSERT INTO bookings (salon_id, staff, email, during)
     SELECT $1, 'Sara', 'old@example.com',
            tstzrange(t, t + interval '1 min')
     FROM generate_series(now(), now() + interval '2 days',
                          interval '1 day') AS t`,
    [b],
  );
  // {w_c_race}
  const results = await Promise.allSettled(
    Array.from({ length: 10 }, (_, i) =>
      book(b, { staff: "Sara", email: `r${i}@example.com`, start: at(11, 10 + i), minutes: 30 }),
    ),
  );
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 2);
  const used = await withSalon(b, (db) => db.query("SELECT count(*)::int AS n FROM bookings"));
  assert.equal(used.rows[0].n, 5);
});

test("{w_t_webhook}", async () => {
  const event = { id: `evt_${a}`, type: "subscription.updated", salon: a, plan: "pro" };
  assert.deepEqual(await apply(event), { applied: true });
  assert.deepEqual(await apply(event), { applied: false });
});
''',
    "metrics.sql": '''-- {w_c_mrr}
SELECT plan, count(*) AS salons, sum(price) / 100 AS mrr_egp
FROM salons JOIN plans ON plans.id = salons.plan
GROUP BY plan ORDER BY plan;
''',
}

LAUNCH = {
    "en": '''# Launch checklist: Bit Booking for every salon

## Product
- [x] Sign-up to first booking in under 5 minutes (measured with 5 salon owners)
- [x] Free plan limit explained before it is reached, with the upgrade path
- [x] Privacy policy and terms published; data export and deletion work

## Safety
- [x] Row-level security on every salon table; test fails if a policy is missing
- [x] Billing webhooks signed and idempotent; replay test passes
- [x] Backups restored into a fresh database this week, and timed

## Delivery
- [x] Pipeline: tests, contract check, image by commit, staged rollout
- [x] Infrastructure in code; staging rebuilt from nothing this week
- [x] Feature flag for sign-ups: can close sign-ups in one click

## Operations
- [x] SLOs: bookings 99.9% available, 99% under 400 ms; burn-rate alerts
- [x] On-call rota for launch week; runbooks for the five likeliest failures
- [x] Status page and support address ready

## After launch
- [ ] Day 1, 7, 30: activation, conversion to Pro, error budget, top complaints
''',
    "ar": '''# قائمة الإطلاق: «بِت للحجوزات» لكل صالون

## المنتج
- [x] من التسجيل إلى أول حجز في أقل من 5 دقائق (قيس مع 5 ملاك صالونات)
- [x] حد الاشتراك المجاني مشروح قبل بلوغه، مع طريق الترقية
- [x] سياسة الخصوصية والشروط منشورة؛ وتصدير البيانات وحذفها يعملان

## الأمان
- [x] أمان مستوى الصف على كل جدول صالون؛ ويفشل اختبار إن غابت سياسة
- [x] أحداث الفوترة موقّعة ومتكررة بأمان؛ واختبار الإعادة ينجح
- [x] استُعيدت النسخ الاحتياطية في قاعدة جديدة هذا الأسبوع، ووُقّتت

## التسليم
- [x] الخط: اختبارات، وفحص العقد، وصورة لكل commit، وإطلاق متدرج
- [x] البنية ككود؛ وأُعيد بناء بيئة الاختبار من لا شيء هذا الأسبوع
- [x] علَم ميزة للتسجيل: يمكن إغلاق التسجيل بنقرة

## التشغيل
- [x] الأهداف: الحجز متاح 99.9%، و99% تحت 400 ms؛ وتنبيهات معدل الاحتراق
- [x] مناوبة لأسبوع الإطلاق؛ وأدلة تشغيل لأرجح خمسة أعطال
- [x] صفحة الحالة وعنوان الدعم جاهزان

## بعد الإطلاق
- [ ] اليوم 1 و7 و30: التفعيل، والتحول إلى Pro، وميزانية الأخطاء، وأكثر الشكاوى
''',
}

SCRIPTS = {
    "book": '''#!/bin/sh
# {w_c_book}
curl -s -X POST localhost:4000/bookings -H "x-api-key: $1" -d "{
  \\"staff\\": \\"Mona\\", \\"email\\": \\"guest@example.com\\",
  \\"start\\": \\"2027-01-05T$2:00Z\\", \\"minutes\\": 30
}"
echo
''',
    "deliver": '''#!/bin/sh
# {w_c_deliver}
hmac=$(printf %s "$1" | openssl dgst -sha256 -hmac whsec_test | cut -d" " -f2)
curl -s -X POST localhost:4000/webhooks/billing \\
  -H "x-signature: sha256=${2:-$hmac}" -d "$1"
echo
''',
}


def record(folder, t):
    s = Session(folder)
    os.environ["PATH"] = str(B4.parent / "b3" / "bin") + ":" + os.environ["PATH"]
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    subprocess.run("psql shop -q -f schema.sql", shell=True, cwd=folder, env=CLEAN, check=True,
                   capture_output=True)
    with Server("node server.ts", folder, "http://localhost:4000/health"):
        s.note(t["w_s_book"])
        for start in ["10:00", "10:15", "11:00", "12:00"]:
            s.run(f"./book key_a {start}")
        s.save(folder / "book.sh")
        s.note(t["w_s_other"])
        s.run("curl -s localhost:4000/bookings -H 'x-api-key: key_b'; echo")
        s.run("curl -s localhost:4000/bookings/1 -H 'x-api-key: key_b'; echo")
        s.run("curl -s localhost:4000/bookings/1 -H 'x-api-key: key_a'; echo")
        s.save(folder / "tenants.sh")
        s.note(t["w_s_upgrade"])
        event = "EVENT='{\"id\":\"evt_1\",\"type\":\"subscription.updated\",\"salon\":1,\"plan\":\"pro\"}'"
        s.run(event)
        for extra in [" forged", "", ""]:
            s.run(f'{event}; ./deliver "$EVENT"{extra}', shown=f'./deliver "$EVENT"{extra}')
        s.run("./book key_a 12:00")
        s.save(folder / "upgrade.sh")
    s.note(t["w_s_rls"])
    app = "APP=postgres://app_user:app@localhost/shop; "
    s.run("APP=postgres://app_user:app@localhost/shop")
    s.run(app + "psql $APP -c 'SELECT count(*) FROM bookings'", shown="psql $APP -c 'SELECT count(*) FROM bookings'")
    cmd = "psql $APP -q -c 'SET app.salon_id = 2' -c 'SELECT id, staff, email FROM bookings'"
    s.run(app + cmd, shown=cmd.replace(" -c 'SELECT", " \\\n    -c 'SELECT"))
    s.save(folder / "rls.sh")
    s.note(t["w_s_metrics"])
    s.run("psql shop -f metrics.sql")
    s.save(folder / "metrics.sh")
    s.note(t["w_s_test"])
    out = s.run("node --test --test-reporter=spec app.test.ts", shown="node --test app.test.ts")
    keep = [l for l in out.split("\n") if l.startswith(("✔", "✖", "ℹ tests", "ℹ pass", "ℹ fail"))]
    s.lines[-len(out.split("\n")):] = keep
    s.save(folder / "test.sh")


for lang, t in T.items():
    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    (folder / "schema.sql").write_text(fill(SCHEMA, t))
    for name, text in FILES.items():
        (folder / name).write_text(fill(text, t))
    (folder / "launch.md").write_text(LAUNCH[lang])
    for name, text in SCRIPTS.items():
        (folder / name).write_text(fill(text, t))
        (folder / name).chmod(0o755)
    (folder / "package.json").write_text('{\n  "private": true,\n  "type": "module"\n}\n')
    os.symlink(B4 / "node_modules", folder / "node_modules")
    subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "70", "--write", "*.ts"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
