"""Writes the examples of Book 3 (Node edition), the chapter "Testing".
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start)

Node's own test runner on a small order API: table-driven unit tests for pricing, integration tests through
app.inject against a real PostgreSQL database (a separate schema per test file, so files run in parallel),
a test double for the mailer, mocked timers for an expiry rule, a failing test to read, and coverage.
What the terminal showed is saved as transcripts (*.sh).
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

URL = "postgres://bit:secret@localhost:5432/shop"

T = {
    "en": dict(
        w_c_pure="pure: the same input always gives the same output, and nothing else happens",
        w_c_vat="VAT of 14% on the discounted subtotal, rounded to the nearest piastre",
        w_c_codes="discount codes: a percentage off, or a fixed amount (never below zero)",
        w_c_mailer="the mailer is passed in, so tests can give a stand-in",
        w_c_expiry="a basket left alone for 30 minutes is released",
        w_c_table="one row per case: adding a case is one line",
        w_c_schema="every test file gets its own schema: files run in parallel without touching each other",
        w_c_fake="a test double: records the calls instead of sending email",
        w_c_clock="the clock is mocked: the test moves time instead of waiting 30 minutes",
        w_c_bug="exercise 1: a bug to find, switched on with BUG=1",
        w_t_plain="no code: subtotal plus VAT", w_t_percent="SAVE10 takes 10% off",
        w_t_fixed="FIXED50 takes 50 pounds off", w_t_floor="a fixed discount never goes below zero",
        w_t_unknown="refuses an unknown code",
        w_t_creates="creates an order with the right total, and sends one confirmation",
        w_t_stock="refuses an order larger than the stock, and changes nothing",
        w_t_fresh="a basket touched recently is kept", w_t_old="a basket left for 30 minutes is released",
        w_d_unknown="unknown discount code",
        w_s_run="All the tests", w_s_one="One file, while working on it", w_s_fail="A test that fails",
        w_s_cover="How much of the code the tests run",
    ),
    "ar": dict(
        w_c_pure="نقية: المدخل نفسه يعطي المخرج نفسه دائماً، ولا يحدث شيء آخر",
        w_c_vat="ضريبة 14% على المجموع بعد الخصم، مقرَّبة إلى أقرب قرش",
        w_c_codes="أكواد الخصم: نسبة مئوية، أو مبلغ ثابت (لا ينزل تحت الصفر أبداً)",
        w_c_mailer="مرسل البريد يُمرَّر، فتعطي الاختبارات بديلاً",
        w_c_expiry="السلة المتروكة 30 دقيقة تُحرَّر",
        w_c_table="صف لكل حالة: إضافة حالة سطر واحد",
        w_c_schema="لكل ملف اختبار مخططه: الملفات تعمل بالتوازي دون أن يمس أحدها الآخر",
        w_c_fake="بديل اختبار: يسجّل الاستدعاءات بدل إرسال البريد",
        w_c_clock="الساعة وهمية: الاختبار يحرّك الوقت بدل انتظار 30 دقيقة",
        w_c_bug="التمرين 1: خطأ يُبحث عنه، يُشغَّل بـ BUG=1",
        w_t_plain="بلا كود: المجموع والضريبة", w_t_percent="SAVE10 تخصم 10%",
        w_t_fixed="FIXED50 تخصم 50 جنيهاً", w_t_floor="الخصم الثابت لا ينزل تحت الصفر أبداً",
        w_t_unknown="يرفض كوداً مجهولاً",
        w_t_creates="ينشئ طلباً بالمجموع الصحيح، ويرسل تأكيداً واحداً",
        w_t_stock="يرفض طلباً أكبر من المخزون، ولا يغيّر شيئاً",
        w_t_fresh="السلة التي لُمست مؤخراً تبقى", w_t_old="السلة المتروكة 30 دقيقة تُحرَّر",
        w_d_unknown="كود خصم مجهول",
        w_s_run="كل الاختبارات", w_s_one="ملف واحد، أثناء العمل عليه", w_s_fail="اختبار يفشل",
        w_s_cover="كم من الكود تنفذه الاختبارات",
    ),
}

FILES = {
    ".env": f"DATABASE_URL={URL}\n",
    "package.json": '''{
  "name": "bit-shop-testing",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --env-file=.env --disable-warning=ExperimentalWarning --test --test-reporter=spec",
    "coverage": "npm test -- --experimental-test-coverage --test-coverage-exclude='test/**'",
    "check": "tsc"
  },
  "dependencies": {
    "fastify": "^5.12.8",
    "kysely": "^0.29.9",
    "pg": "^8.23.1"
  },
  "devDependencies": {
    "@types/node": "^22.20.5",
    "@types/pg": "^8.23.1",
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
  "include": ["src", "test"]
}
''',
    "src/pricing.ts": '''// {w_c_pure}
export type Line = { price: number; quantity: number };

const CODES: Record<string, { percent?: number; amount?: number }> = {
  SAVE10: { percent: 10 },
  FIXED50: { amount: 5000 },
};

export function total(lines: Line[], code?: string) {
  const subtotal = lines.reduce((sum, l) => sum + l.price * l.quantity, 0);
  let discount = 0;
  if (code) {
    // {w_c_codes}
    const rule = CODES[code];
    if (!rule) throw new Error(`{w_d_unknown}: ${code}`);
    discount = rule.percent ? Math.round((subtotal * rule.percent) / 100) : rule.amount!;
    discount = Math.min(discount, subtotal);
  }
  // {w_c_vat}
  // {w_c_bug}
  const rate = process.env.BUG ? 0.15 : 0.14;
  const vat = Math.round((subtotal - discount) * rate);
  return { subtotal, discount, vat, total: subtotal - discount + vat };
}
''',
    "src/baskets.ts": '''// {w_c_expiry}
export const EXPIRES_AFTER = 30 * 60 * 1000;

export function isExpired(lastTouched: number, now = Date.now()) {
  return now - lastTouched >= EXPIRES_AFTER;
}
''',
    "src/db.ts": '''import { type Generated, Kysely, PostgresDialect } from "kysely";
import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

export type DB = {
  products: { id: number; name: string; price: number; stock: number };
  orders: { id: Generated<number>; email: string; total: number };
};

export function connect(schema = "public") {
  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    options: `-c search_path=${schema}`,
  });
  return new Kysely<DB>({ dialect: new PostgresDialect({ pool }) });
}

export const SCHEMA = `
  CREATE TABLE products (id bigint PRIMARY KEY, name text NOT NULL,
    price integer NOT NULL, stock integer NOT NULL CHECK (stock >= 0));
  CREATE TABLE orders (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text NOT NULL, total integer NOT NULL);`;
''',
    "src/app.ts": '''import Fastify from "fastify";
import type { Kysely } from "kysely";
import type { DB } from "./db.ts";
import { total } from "./pricing.ts";

export type Mailer = { send(to: string, subject: string): Promise<void> };

// {w_c_mailer}
export function buildApp(db: Kysely<DB>, mailer: Mailer) {
  const app = Fastify();

  app.post<{ Body: { email: string; productId: number; quantity: number; code?: string } }>(
    "/orders",
    async (request, reply) => {
      const { email, productId, quantity, code } = request.body;
      const order = await db.transaction().execute(async (trx) => {
        const product = await trx
          .updateTable("products")
          .set((eb) => ({ stock: eb("stock", "-", quantity) }))
          .where("id", "=", productId)
          .where("stock", ">=", quantity)
          .returning(["price"])
          .executeTakeFirst();
        if (!product) return undefined;
        const sum = total([{ price: product.price, quantity }], code);
        return trx
          .insertInto("orders")
          .values({ email, total: sum.total })
          .returning(["id", "total"])
          .executeTakeFirstOrThrow();
      });
      if (!order) return reply.code(409).send({ title: "Not enough stock" });
      await mailer.send(email, `Order ${order.id}`);
      return reply.code(201).send(order);
    },
  );
  return app;
}
''',
    "test/pricing.test.ts": '''import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { total } from "../src/pricing.ts";

const kit = { price: 45000, quantity: 1 };
const wheels = { price: 6000, quantity: 2 };

describe("total", () => {
  // {w_c_table}
  const cases = [
    { name: "{w_t_plain}", code: undefined, want: { discount: 0, vat: 7980, total: 64980 } },
    { name: "{w_t_percent}", code: "SAVE10", want: { discount: 5700, vat: 7182, total: 58482 } },
    { name: "{w_t_fixed}", code: "FIXED50", want: { discount: 5000, vat: 7280, total: 59280 } },
  ];
  for (const c of cases) {
    it(c.name, () => {
      assert.partialDeepStrictEqual(total([kit, wheels], c.code), c.want);
    });
  }

  it("{w_t_floor}", () => {
    const cheap = [{ price: 3000, quantity: 1 }];
    assert.deepEqual(total(cheap, "FIXED50"), { subtotal: 3000, discount: 3000, vat: 0, total: 0 });
  });

  it("{w_t_unknown}", () => {
    assert.throws(() => total([kit], "FREE"), /FREE/);
  });
});
''',
    "test/orders.test.ts": '''import assert from "node:assert/strict";
import { after, before, beforeEach, mock, test } from "node:test";
import { sql } from "kysely";
import { buildApp } from "../src/app.ts";
import { connect, SCHEMA } from "../src/db.ts";

// {w_c_schema}
const schema = `test_${process.pid}`;
const db = connect(schema);
// {w_c_fake}
const mailer = { send: mock.fn(async (_to: string, _subject: string) => {}) };
const app = buildApp(db, mailer);

before(async () => {
  await sql.raw(`CREATE SCHEMA ${schema}; SET search_path = ${schema}; ${SCHEMA}`).execute(db);
});
beforeEach(async () => {
  await sql`TRUNCATE orders RESTART IDENTITY; DELETE FROM products`.execute(db);
  await db.insertInto("products").values({ id: 1, name: "Kit", price: 45000, stock: 3 }).execute();
  mailer.send.mock.resetCalls();
});
after(async () => {
  await sql.raw(`DROP SCHEMA ${schema} CASCADE`).execute(db);
  await Promise.all([app.close(), db.destroy()]);
});

const order = (quantity: number) =>
  app.inject({
    method: "POST",
    url: "/orders",
    payload: { email: "sara@example.com", productId: 1, quantity, code: "SAVE10" },
  });

test("{w_t_creates}", async () => {
  const res = await order(2);
  assert.equal(res.statusCode, 201);
  assert.deepEqual(res.json(), { id: 1, total: 92340 });
  const { stock } = await db.selectFrom("products").select("stock").executeTakeFirstOrThrow();
  assert.equal(stock, 1);
  assert.equal(mailer.send.mock.callCount(), 1);
  assert.deepEqual(mailer.send.mock.calls[0]?.arguments, ["sara@example.com", "Order 1"]);
});

test("{w_t_stock}", async () => {
  const res = await order(4);
  assert.equal(res.statusCode, 409);
  const orders = await db.selectFrom("orders").selectAll().execute();
  assert.equal(orders.length, 0);
  assert.equal(mailer.send.mock.callCount(), 0);
});
''',
    "test/baskets.test.ts": '''import assert from "node:assert/strict";
import { test } from "node:test";
import { isExpired } from "../src/baskets.ts";

test("{w_t_fresh}", (t) => {
  // {w_c_clock}
  t.mock.timers.enable({ apis: ["Date"], now: 0 });
  const touched = Date.now();
  t.mock.timers.tick(29 * 60 * 1000);
  assert.equal(isExpired(touched), false);
});

test("{w_t_old}", (t) => {
  t.mock.timers.enable({ apis: ["Date"], now: 0 });
  const touched = Date.now();
  t.mock.timers.tick(30 * 60 * 1000);
  assert.equal(isExpired(touched), true);
});
''',
}


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("npx tsc")
    s.lines.clear()
    clean = " 2>&1 | grep -v '^$' | sed -E 's/\\(([0-9.]+)ms\\)/(…ms)/; s/duration_ms [0-9.]+/duration_ms …/'"
    s.note(t["w_s_run"])
    s.run("npm test --silent" + clean, shown="npm test")
    s.save(folder / "run.sh")
    s.note(t["w_s_one"])
    s.run("npm test --silent -- test/pricing.test.ts" + clean + " | head -8",
          shown="npm test -- test/pricing.test.ts")
    s.save(folder / "one.sh")
    s.note(t["w_s_fail"])
    s.run("BUG=1 npm test --silent -- test/pricing.test.ts" + clean + " | sed -n '16,32p'", check=False,
          shown="BUG=1 npm test -- test/pricing.test.ts")
    s.save(folder / "fail.sh")
    s.note(t["w_s_cover"])
    s.run("npm run coverage --silent 2>&1 | sed -n '/start of coverage/,/end of coverage/p' | sed 's/^ℹ //'",
          shown="npm run coverage")
    s.save(folder / "coverage.sh")


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    os.symlink(B3 / "node_modules", folder / "node_modules")
    subprocess.run(["npx", "prettier", "--print-width", "84", "--write", "src", "test"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
