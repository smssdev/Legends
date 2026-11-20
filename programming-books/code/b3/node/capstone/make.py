"""Writes the examples of Book 3 (Node edition), the capstone chapter "Capstone: The Bit Shop API, from an
Empty Folder to a Running Container".
Run: python3 make.py   (PostgreSQL and Redis through code/b3/bin/pg-start and bin/redis-start, then Docker)

One API with everything the book built: accounts and tokens, products with cursor pages over an index,
orders in one transaction with an Idempotency-Key and an outbox row, a worker that sends the outbox's
emails, a login limit kept in Redis, Problem Details, JSON logs, metrics and health checks, tests against
a real database, and a multi-stage image run by Compose with its database, Redis and worker.
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

T = {
    "en": dict(
        w_p1="Robot kit", w_p2="Spare wheels", w_p3="Soldering iron", w_p4="Battery pack", w_p5="Sensor set",
        w_c_config="every setting comes from the environment, checked once at start-up: a missing one stops the app here, not at the first request",
        w_c_problem="every error leaves as Problem Details (Chapter 3)",
        w_c_hash="only the token's hash is stored: a leaked table opens no account",
        w_c_who="who is calling? (Authorization: Bearer <token>)",
        w_c_dummy="an unknown email still costs one hash, so timing does not reveal which emails exist",
        w_c_limit="5 tries a minute per address and email, counted in Redis: every copy of the app shares the count",
        w_c_cursor="the cursor is the last row's price and id; the index (price, id) finds where to start",
        w_c_key="the client's key makes a retry safe: the same key returns the same order",
        w_c_once="all or nothing: the order, its lines, the stock and the outbox row commit together",
        w_c_replay="the key was used before: return that order, unless the body is different",
        w_c_stock="the stock is taken only if it is enough, in the same statement",
        w_c_outbox="the email is a row in the same transaction; the worker sends it after the commit",
        w_c_metrics="requests by route and status, and how long they took",
        w_c_ready="ready means the database and Redis both answer",
        w_c_root="the composition root: the only file that creates connections",
        w_c_close="on SIGTERM: stop taking requests, finish the ones in flight, then close the connections",
        w_c_skip="SKIP LOCKED: two workers never take the same row",
        w_c_worker="the worker: send what the outbox holds, mark it sent, repeat",
        w_c_fresh="each test starts from the schema file, on its own database",
        w_m_unauth="Not signed in", w_m_unauth_d="Send a valid token: Authorization: Bearer <token>.",
        w_m_login="Email or password is wrong", w_m_taken="Email already registered",
        w_m_invalid="Invalid request", w_m_many="Too many attempts", w_m_many_d="Try again in {seconds} seconds.",
        w_m_none="Not found", w_m_stock="Not enough stock", w_m_stock_d="Product {id} has {stock} left.",
        w_m_unknown="Unknown product", w_m_reused="Idempotency-Key reused",
        w_m_reused_d="This key was used with a different body.", w_m_server="Server error",
        w_m_cursor="invalid cursor",
        w_t_order="places an order once, however many times the same key is sent",
        w_t_reused="refuses a key reused with another body",
        w_t_stock="takes no stock when one line is short",
        w_t_token="refuses an order without a token",
        w_t_pages="pages follow each other with no gaps and no repeats",
        w_s_tree="The project", w_s_test="The tests, against PostgreSQL and Redis",
        w_s_build="The image", w_s_up="The whole system: database, Redis, the API and the worker",
        w_s_register="An account", w_s_login="A token", w_s_page="The first page of products, cheapest first",
        w_s_next="The next page, from the cursor", w_s_order="An order, with a key the client chose",
        w_s_retry="The network failed and the client sends it again, with the same key",
        w_s_short="More than the stock", w_s_anon="No token", w_s_guess="Someone guesses a password",
        w_s_metrics="What Prometheus would collect", w_s_worker="The worker sent the email, once",
        w_s_logs="One request in the API's log", w_s_down="Stop everything and delete the data",
    ),
    "ar": dict(
        w_p1="عدة الروبوت", w_p2="عجلات احتياطية", w_p3="كاوية لحام", w_p4="حزمة بطاريات", w_p5="طقم حساسات",
        w_c_config="كل إعداد من البيئة، ويُفحص مرة عند البدء: الناقص يوقف التطبيق هنا، لا عند أول طلب",
        w_c_problem="كل خطأ يخرج بصيغة Problem Details (الفصل 3)",
        w_c_hash="لا يُخزَّن إلا بصمة الرمز: جدول مسرَّب لا يفتح أي حساب",
        w_c_who="من المتصل؟ (Authorization: Bearer <token>)",
        w_c_dummy="البريد المجهول يكلّف بصمة واحدة أيضاً، فلا يكشف الوقت أي البُرُد موجود",
        w_c_limit="5 محاولات في الدقيقة لكل عنوان وبريد، تُعدّ في Redis: كل نسخ التطبيق تتشارك العدّ",
        w_c_cursor="المؤشر هو سعر آخر صف ورقمه؛ والفهرس (price, id) يجد من أين يبدأ",
        w_c_key="مفتاح العميل يجعل إعادة المحاولة آمنة: المفتاح نفسه يعيد الطلب نفسه",
        w_c_once="الكل أو لا شيء: الطلب وبنوده والمخزون وصف الصندوق الصادر تُعتمد معاً",
        w_c_replay="المفتاح استُعمل من قبل: أعد ذلك الطلب، إلا إن اختلف الجسم",
        w_c_stock="لا يؤخذ المخزون إلا إن كفى، في الجملة نفسها",
        w_c_outbox="البريد صف في المعاملة نفسها؛ والعامل يرسله بعد الاعتماد",
        w_c_metrics="الطلبات حسب المسار والحالة، وكم استغرقت",
        w_c_ready="الجاهزية أن تجيب قاعدة البيانات وRedis معاً",
        w_c_root="جذر التركيب: الملف الوحيد الذي ينشئ الاتصالات",
        w_c_close="عند SIGTERM: توقّف عن قبول الطلبات، وأنهِ الجارية، ثم أغلق الاتصالات",
        w_c_skip="SKIP LOCKED: لا يأخذ عاملان الصف نفسه أبداً",
        w_c_worker="العامل: أرسل ما في الصندوق الصادر، وعلّمه مُرسلاً، وكرّر",
        w_c_fresh="كل اختبار يبدأ من ملف المخطط، على قاعدة بياناته الخاصة",
        w_m_unauth="لم تسجّل الدخول", w_m_unauth_d="أرسل رمزاً صالحاً: Authorization: Bearer <token>.",
        w_m_login="البريد أو كلمة المرور خطأ", w_m_taken="البريد مسجّل من قبل",
        w_m_invalid="طلب غير صالح", w_m_many="محاولات كثيرة", w_m_many_d="حاول بعد {seconds} ثانية.",
        w_m_none="غير موجود", w_m_stock="المخزون لا يكفي", w_m_stock_d="بقي من المنتج {id}: {stock}.",
        w_m_unknown="منتج مجهول", w_m_reused="مفتاح Idempotency-Key مستعمل",
        w_m_reused_d="استُعمل هذا المفتاح بجسم مختلف.", w_m_server="خطأ في الخادم",
        w_m_cursor="مؤشر غير صالح",
        w_t_order="places an order once, however many times the same key is sent",
        w_t_reused="refuses a key reused with another body",
        w_t_stock="takes no stock when one line is short",
        w_t_token="refuses an order without a token",
        w_t_pages="pages follow each other with no gaps and no repeats",
        w_s_tree="المشروع", w_s_test="الاختبارات، على PostgreSQL وRedis",
        w_s_build="الصورة", w_s_up="النظام كله: قاعدة البيانات وRedis والـ API والعامل",
        w_s_register="حساب", w_s_login="رمز", w_s_page="أول صفحة من المنتجات، الأرخص أولاً",
        w_s_next="الصفحة التالية، من المؤشر", w_s_order="طلب، بمفتاح اختاره العميل",
        w_s_retry="فشلت الشبكة فأعاد العميل الإرسال، بالمفتاح نفسه",
        w_s_short="أكثر من المخزون", w_s_anon="بلا رمز", w_s_guess="أحدهم يخمّن كلمة مرور",
        w_s_metrics="ما سيجمعه Prometheus", w_s_worker="العامل أرسل البريد، مرة واحدة",
        w_s_logs="طلب واحد في سجل الـ API", w_s_down="أوقف كل شيء واحذف البيانات",
    ),
}

FILES = {
    ".env": "DATABASE_URL=postgres://bit:secret@localhost:5432/shop\nREDIS_URL=redis://localhost:6379\n",
    ".env.test": "DATABASE_URL=postgres://bit:secret@localhost:5432/shop_test\nREDIS_URL=redis://localhost:6379\n"
                 "LOG_LEVEL=silent\n",
    ".dockerignore": "node_modules\n.env\n.env.test\ntest\n",
    "package.json": '''{
  "name": "bit-shop",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node --env-file=.env src/server.ts",
    "worker": "node --env-file=.env src/worker.ts",
    "test": "node --env-file=.env.test --test --test-reporter=spec",
    "check": "tsc"
  },
  "dependencies": {
    "@fastify/rate-limit": "11.2.2",
    "fastify": "5.12.8",
    "fastify-type-provider-zod": "7.0.0",
    "ioredis": "6.0.0",
    "kysely": "0.29.9",
    "pg": "8.23.1",
    "prom-client": "15.1.3",
    "zod": "4.6.7"
  },
  "devDependencies": {
    "@types/node": "22.20.5",
    "@types/pg": "8.23.1",
    "typescript": "7.0.2"
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
    "schema.sql": '''CREATE TABLE users (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL
);
CREATE TABLE sessions (
  token_hash text PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL
);
CREATE TABLE products (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  price integer NOT NULL CHECK (price > 0),
  stock integer NOT NULL CHECK (stock >= 0)
);
CREATE INDEX products_price_id ON products (price, id);
CREATE TABLE orders (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users (id),
  idempotency_key text NOT NULL,
  request_hash text NOT NULL,
  total integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, idempotency_key)
);
CREATE TABLE order_items (
  order_id bigint NOT NULL REFERENCES orders (id),
  product_id bigint NOT NULL REFERENCES products (id),
  quantity integer NOT NULL CHECK (quantity > 0),
  price integer NOT NULL,
  PRIMARY KEY (order_id, product_id)
);
CREATE TABLE outbox (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  topic text NOT NULL,
  payload jsonb NOT NULL,
  sent_at timestamptz
);
INSERT INTO products (name, price, stock) VALUES
  ('{w_p1}', 45000, 5), ('{w_p2}', 6000, 50), ('{w_p3}', 18000, 12),
  ('{w_p4}', 9000, 30), ('{w_p5}', 25000, 8);
''',
    "src/config.ts": '''import { z } from "zod";

// {w_c_config}
export const config = z
  .object({
    DATABASE_URL: z.url(),
    REDIS_URL: z.url(),
    PORT: z.coerce.number().int().default(3000),
    LOG_LEVEL: z.enum(["silent", "error", "warn", "info", "debug"]).default("info"),
  })
  .parse(process.env);
''',
    "src/db.ts": '''import { type Generated, Kysely, PostgresDialect } from "kysely";
import pg from "pg";
import { config } from "./config.ts";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

export type DB = {
  users: { id: Generated<number>; email: string; password_hash: string };
  sessions: { token_hash: string; user_id: number; expires_at: Date };
  products: { id: Generated<number>; name: string; price: number; stock: number };
  orders: {
    id: Generated<number>;
    user_id: number;
    idempotency_key: string;
    request_hash: string;
    total: Generated<number>;
    created_at: Generated<Date>;
  };
  order_items: { order_id: number; product_id: number; quantity: number; price: number };
  outbox: { id: Generated<number>; topic: string; payload: unknown; sent_at: Date | null };
};

export const connect = () =>
  new Kysely<DB>({
    dialect: new PostgresDialect({
      pool: new pg.Pool({ connectionString: config.DATABASE_URL, max: 10 }),
    }),
  });
''',
    "src/problem.ts": '''// {w_c_problem}
export class Problem extends Error {
  status: number;
  detail?: string;
  extra: Record<string, unknown>;

  constructor(status: number, title: string, detail?: string, extra = {}) {
    super(title);
    this.status = status;
    this.detail = detail;
    this.extra = extra;
  }

  body(instance: string) {
    const { status, detail } = this;
    return { title: this.message, status, ...(detail && { detail }), instance, ...this.extra };
  }
}

const say = (text: string, values: Record<string, unknown>) =>
  text.replace(/\\{(\\w+)\\}/g, (_, k: string) => String(values[k]));

export const problems = {
  unauthenticated: () => new Problem(401, "{w_m_unauth}", "{w_m_unauth_d}"),
  badLogin: () => new Problem(401, "{w_m_login}"),
  notFound: () => new Problem(404, "{w_m_none}"),
  emailTaken: () => new Problem(409, "{w_m_taken}"),
  outOfStock: (id: number, stock: number) =>
    new Problem(409, "{w_m_stock}", say("{w_m_stock_d}", { id, stock })),
  keyReused: () => new Problem(422, "{w_m_reused}", "{w_m_reused_d}"),
  unknownProduct: (id: number) => new Problem(422, "{w_m_unknown}", undefined, { product_id: id }),
  invalid: (errors: { field: string; message: string }[]) =>
    new Problem(422, "{w_m_invalid}", undefined, { errors }),
  tooMany: (seconds: number) => new Problem(429, "{w_m_many}", say("{w_m_many_d}", { seconds })),
  server: () => new Problem(500, "{w_m_server}"),
};
''',
    "src/password.ts": '''import { randomBytes, scrypt, timingSafeEqual } from "node:crypto";

const COST = 2 ** 15;

function derive(password: string, salt: Buffer, cost: number) {
  return new Promise<Buffer>((resolve, reject) => {
    const options = { N: cost, r: 8, p: 1, maxmem: 64 * 1024 * 1024 };
    scrypt(password.normalize("NFKC"), salt, 32, options, (error, key) =>
      error ? reject(error) : resolve(key),
    );
  });
}

export async function hashPassword(password: string) {
  const salt = randomBytes(16);
  const key = await derive(password, salt, COST);
  return ["scrypt", COST, salt.toString("base64url"), key.toString("base64url")].join("$");
}

export async function verifyPassword(password: string, stored: string) {
  const [, cost, salt, key] = stored.split("$");
  const expected = Buffer.from(key ?? "", "base64url");
  const actual = await derive(password, Buffer.from(salt ?? "", "base64url"), Number(cost));
  return timingSafeEqual(actual, expected);
}
''',
    "src/auth.ts": '''import { createHash, randomBytes } from "node:crypto";
import type { FastifyRequest } from "fastify";
import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { sql } from "kysely";
import { z } from "zod";
import type { Deps } from "./app.ts";
import { hashPassword, verifyPassword } from "./password.ts";
import { problems } from "./problem.ts";

declare module "fastify" {
  interface FastifyRequest {
    userId?: number;
  }
}

const digest = (token: string) => createHash("sha256").update(token).digest("hex");
const Email = z.email().max(254).toLowerCase();
const DUMMY = await hashPassword("not anyone's password");

// {w_c_who}
export const authenticate = ({ db }: Deps) =>
  async function (request: FastifyRequest) {
    const [scheme, token] = (request.headers.authorization ?? "").split(" ");
    if (scheme !== "Bearer" || !token) throw problems.unauthenticated();
    const session = await db
      .selectFrom("sessions")
      .select("user_id")
      .where("token_hash", "=", digest(token))
      .where("expires_at", ">", sql<Date>`now()`)
      .executeTakeFirst();
    if (!session) throw problems.unauthenticated();
    request.userId = session.user_id;
  };

export const authRoutes =
  ({ db }: Deps): FastifyPluginAsyncZod =>
  async (app) => {
    app.post(
      "/auth/register",
      { schema: { body: z.strictObject({ email: Email, password: z.string().min(12).max(128) }) } },
      async (request, reply) => {
        const { email, password } = request.body;
        const user = await db
          .insertInto("users")
          .values({ email, password_hash: await hashPassword(password) })
          .onConflict((c) => c.column("email").doNothing())
          .returning(["id", "email"])
          .executeTakeFirst();
        if (!user) throw problems.emailTaken();
        return reply.code(201).send(user);
      },
    );

    app.post(
      "/auth/login",
      {
        // {w_c_limit}
        config: {
          rateLimit: {
            max: 5,
            timeWindow: "1 minute",
            hook: "preHandler",
            keyGenerator: (request) =>
              `login:${request.ip}:${(request.body as { email?: string }).email}`,
          },
        },
        schema: { body: z.strictObject({ email: Email, password: z.string().max(128) }) },
      },
      async (request) => {
        const { email, password } = request.body;
        const user = await db
          .selectFrom("users")
          .select(["id", "password_hash"])
          .where("email", "=", email)
          .executeTakeFirst();
        // {w_c_dummy}
        const ok = await verifyPassword(password, user?.password_hash ?? DUMMY);
        if (!user || !ok) throw problems.badLogin();
        const token = randomBytes(32).toString("base64url");
        // {w_c_hash}
        await db
          .insertInto("sessions")
          .values({
            token_hash: digest(token),
            user_id: user.id,
            expires_at: sql`now() + interval '30 days'`,
          })
          .execute();
        return { token };
      },
    );
  };
''',
    "src/products.ts": '''import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import type { Deps } from "./app.ts";
import { problems } from "./problem.ts";

const encode = (price: number, id: number) =>
  Buffer.from(JSON.stringify([price, id])).toString("base64url");

const Position = z.tuple([z.number().int(), z.number().int()]);

function decode(cursor: string) {
  try {
    return Position.parse(JSON.parse(Buffer.from(cursor, "base64url").toString()));
  } catch {
    throw problems.invalid([{ field: "querystring.cursor", message: "{w_m_cursor}" }]);
  }
}

export const productRoutes =
  ({ db }: Deps): FastifyPluginAsyncZod =>
  async (app) => {
    app.get(
      "/products",
      {
        schema: {
          querystring: z.object({
            limit: z.coerce.number().int().min(1).max(50).default(20),
            cursor: z.string().max(100).optional(),
          }),
        },
      },
      async (request) => {
        const { limit, cursor } = request.query;
        let query = db
          .selectFrom("products")
          .select(["id", "name", "price", "stock"])
          .orderBy("price")
          .orderBy("id")
          .limit(limit + 1);
        if (cursor) {
          // {w_c_cursor}
          const [price, id] = decode(cursor);
          query = query.where((eb) =>
            eb(eb.refTuple("price", "id"), ">", eb.tuple(price, id)),
          );
        }
        const rows = await query.execute();
        const page = rows.slice(0, limit);
        const last = page.at(-1);
        return {
          data: page,
          next_cursor: rows.length > limit && last ? encode(last.price, last.id) : null,
        };
      },
    );
  };
''',
    "src/orders.ts": '''import { createHash } from "node:crypto";
import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import type { Deps } from "./app.ts";
import { authenticate } from "./auth.ts";
import { problems } from "./problem.ts";

const Body = z.strictObject({
  items: z
    .array(
      z.strictObject({
        product_id: z.number().int().positive(),
        quantity: z.number().int().min(1).max(10),
      }),
    )
    .min(1)
    .max(20),
});

export const orderRoutes =
  (deps: Deps): FastifyPluginAsyncZod =>
  async (app) => {
    const { db } = deps;
    app.addHook("preHandler", authenticate(deps));

    app.post(
      "/orders",
      {
        schema: {
          body: Body,
          // {w_c_key}
          headers: z.looseObject({ "idempotency-key": z.string().min(8).max(100) }),
        },
      },
      async (request, reply) => {
        const userId = request.userId!;
        const key = request.headers["idempotency-key"];
        const hash = createHash("sha256").update(JSON.stringify(request.body)).digest("hex");

        // {w_c_once}
        const result = await db.transaction().execute(async (trx) => {
          const created = await trx
            .insertInto("orders")
            .values({ user_id: userId, idempotency_key: key, request_hash: hash })
            .onConflict((c) => c.columns(["user_id", "idempotency_key"]).doNothing())
            .returning("id")
            .executeTakeFirst();
          if (!created) {
            // {w_c_replay}
            const old = await trx
              .selectFrom("orders")
              .select(["id", "request_hash"])
              .where("user_id", "=", userId)
              .where("idempotency_key", "=", key)
              .executeTakeFirstOrThrow();
            if (old.request_hash !== hash) throw problems.keyReused();
            return { id: old.id, replayed: true };
          }

          let total = 0;
          for (const { product_id, quantity } of request.body.items) {
            // {w_c_stock}
            const product = await trx
              .updateTable("products")
              .set((eb) => ({ stock: eb("stock", "-", quantity) }))
              .where("id", "=", product_id)
              .where("stock", ">=", quantity)
              .returning("price")
              .executeTakeFirst();
            if (!product) {
              const left = await trx
                .selectFrom("products")
                .select("stock")
                .where("id", "=", product_id)
                .executeTakeFirst();
              throw left
                ? problems.outOfStock(product_id, left.stock)
                : problems.unknownProduct(product_id);
            }
            total += product.price * quantity;
            await trx
              .insertInto("order_items")
              .values({ order_id: created.id, product_id, quantity, price: product.price })
              .execute();
          }
          await trx.updateTable("orders").set({ total }).where("id", "=", created.id).execute();
          // {w_c_outbox}
          await trx
            .insertInto("outbox")
            .values({ topic: "order.placed", payload: JSON.stringify({ order_id: created.id }) })
            .execute();
          return { id: created.id, replayed: false };
        });

        const order = await findOrder(deps, userId, result.id);
        if (result.replayed) reply.header("idempotent-replayed", "true");
        return reply.code(result.replayed ? 200 : 201).send(order);
      },
    );

    app.get(
      "/orders/:id",
      { schema: { params: z.object({ id: z.coerce.number().int().positive() }) } },
      async (request) => {
        const order = await findOrder(deps, request.userId!, request.params.id);
        if (!order) throw problems.notFound();
        return order;
      },
    );
  };

async function findOrder({ db }: Deps, userId: number, id: number) {
  const order = await db
    .selectFrom("orders")
    .select(["id", "total", "created_at"])
    .where("id", "=", id)
    .where("user_id", "=", userId)
    .executeTakeFirst();
  if (!order) return undefined;
  const items = await db
    .selectFrom("order_items")
    .select(["product_id", "quantity", "price"])
    .where("order_id", "=", id)
    .orderBy("product_id")
    .execute();
  return { ...order, items };
}
''',
    "src/metrics.ts": '''import type { FastifyInstance } from "fastify";
import client from "prom-client";

// {w_c_metrics}
const requests = new client.Counter({
  name: "http_requests_total",
  help: "Requests by route and status",
  labelNames: ["method", "route", "status"],
});
const duration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "How long requests took",
  labelNames: ["route"],
  buckets: [0.01, 0.05, 0.1, 0.5, 1],
});

export function measure(app: FastifyInstance) {
  app.addHook("onResponse", async (request, reply) => {
    const route = request.routeOptions.url ?? "unknown";
    if (["/health", "/ready", "/metrics"].includes(route)) return;
    requests.inc({ method: request.method, route, status: reply.statusCode });
    duration.observe({ route }, reply.elapsedTime / 1000);
  });
  app.get("/metrics", async (_request, reply) =>
    reply.type(client.register.contentType).send(await client.register.metrics()),
  );
}
''',
    "src/app.ts": '''import rateLimit from "@fastify/rate-limit";
import Fastify, { type FastifyError } from "fastify";
import {
  hasZodFastifySchemaValidationErrors,
  serializerCompiler,
  validatorCompiler,
} from "fastify-type-provider-zod";
import type { Redis } from "ioredis";
import { type Kysely, sql } from "kysely";
import { authRoutes } from "./auth.ts";
import { config } from "./config.ts";
import type { DB } from "./db.ts";
import { measure } from "./metrics.ts";
import { orderRoutes } from "./orders.ts";
import { Problem, problems } from "./problem.ts";
import { productRoutes } from "./products.ts";

export type Deps = { db: Kysely<DB>; redis: Redis };

export async function buildApp(deps: Deps) {
  const app = Fastify({ logger: { level: config.LOG_LEVEL } });
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);
  await app.register(rateLimit, { global: false, redis: deps.redis });

  app.setErrorHandler((error: FastifyError, request, reply) => {
    let problem: Problem;
    if (error instanceof Problem) {
      problem = error;
    } else if (hasZodFastifySchemaValidationErrors(error)) {
      problem = problems.invalid(
        error.validation.map((issue) => ({
          field: [error.validationContext, ...String(issue.instancePath).split("/")]
            .filter(Boolean)
            .join("."),
          message: issue.message ?? "",
        })),
      );
    } else if (error.statusCode === 429) {
      problem = problems.tooMany(Number(reply.getHeader("retry-after") ?? 60));
    } else {
      request.log.error(error);
      problem = problems.server();
    }
    reply.code(problem.status).type("application/problem+json");
    return reply.send(problem.body(request.url));
  });

  measure(app);
  await app.register(authRoutes(deps));
  await app.register(productRoutes(deps));
  await app.register(orderRoutes(deps));

  app.get("/health", async () => ({ ok: true }));
  // {w_c_ready}
  app.get("/ready", async (_request, reply) => {
    try {
      await sql`SELECT 1`.execute(deps.db);
      await deps.redis.ping();
      return { ready: true };
    } catch {
      return reply.code(503).send({ ready: false });
    }
  });
  return app;
}
''',
    "src/server.ts": '''import { Redis } from "ioredis";
import { buildApp } from "./app.ts";
import { config } from "./config.ts";
import { connect } from "./db.ts";

// {w_c_root}
const db = connect();
const redis = new Redis(config.REDIS_URL, { maxRetriesPerRequest: 1 });
const app = await buildApp({ db, redis });
await app.listen({ host: "0.0.0.0", port: config.PORT });

// {w_c_close}
process.once("SIGTERM", async () => {
  await app.close();
  await db.destroy();
  await redis.quit();
});
''',
    "src/worker.ts": '''import { setTimeout as sleep } from "node:timers/promises";
import { sql } from "kysely";
import { connect } from "./db.ts";

const db = connect();
let running = true;
process.once("SIGTERM", () => (running = false));

// {w_c_worker}
while (running) {
  const sent = await db.transaction().execute(async (trx) => {
    const rows = await trx
      .selectFrom("outbox")
      .select(["id", "payload"])
      .where("sent_at", "is", null)
      .orderBy("id")
      .limit(10)
      // {w_c_skip}
      .forUpdate()
      .skipLocked()
      .execute();
    for (const row of rows) {
      const { order_id } = row.payload as { order_id: number };
      const { email } = await trx
        .selectFrom("orders")
        .innerJoin("users", "users.id", "orders.user_id")
        .select("users.email")
        .where("orders.id", "=", order_id)
        .executeTakeFirstOrThrow();
      console.log(JSON.stringify({ msg: "email sent", to: email, order_id }));
      await trx
        .updateTable("outbox")
        .set({ sent_at: sql`now()` })
        .where("id", "=", row.id)
        .execute();
    }
    return rows.length;
  });
  if (sent === 0) await sleep(500);
}
await db.destroy();
''',
    "test/api.test.ts": '''import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { after, beforeEach, test } from "node:test";
import { Redis } from "ioredis";
import { sql } from "kysely";
import { buildApp } from "../src/app.ts";
import { config } from "../src/config.ts";
import { connect } from "../src/db.ts";

const db = connect();
const redis = new Redis(config.REDIS_URL);
const app = await buildApp({ db, redis });
const schema = readFileSync("schema.sql", "utf8");

// {w_c_fresh}
beforeEach(async () => {
  await sql.raw(`DROP SCHEMA public CASCADE; CREATE SCHEMA public; ${schema}`).execute(db);
});
after(async () => {
  await app.close();
  await db.destroy();
  await redis.quit();
});

async function signIn() {
  const user = { email: "sara@example.com", password: "a long password" };
  await app.inject({ method: "POST", url: "/auth/register", body: user });
  const res = await app.inject({ method: "POST", url: "/auth/login", body: user });
  return { authorization: `Bearer ${res.json().token}` };
}

const order = (headers: object, key: string, items: object[]) =>
  app.inject({
    method: "POST",
    url: "/orders",
    headers: { ...headers, "idempotency-key": key },
    body: { items },
  });

const stock = async (id: number) =>
  (await db.selectFrom("products").select("stock").where("id", "=", id).executeTakeFirstOrThrow())
    .stock;

test("{w_t_order}", async () => {
  const auth = await signIn();
  const items = [{ product_id: 2, quantity: 3 }];
  const first = await order(auth, "key-0001", items);
  const again = await order(auth, "key-0001", items);
  assert.equal(first.statusCode, 201);
  assert.equal(again.statusCode, 200);
  assert.equal(again.json().id, first.json().id);
  assert.equal(await stock(2), 47);
  const outbox = await db.selectFrom("outbox").selectAll().execute();
  assert.equal(outbox.length, 1);
});

test("{w_t_reused}", async () => {
  const auth = await signIn();
  await order(auth, "key-0002", [{ product_id: 2, quantity: 1 }]);
  const res = await order(auth, "key-0002", [{ product_id: 2, quantity: 2 }]);
  assert.equal(res.statusCode, 422);
});

test("{w_t_stock}", async () => {
  const auth = await signIn();
  const res = await order(auth, "key-0003", [
    { product_id: 2, quantity: 1 },
    { product_id: 1, quantity: 6 },
  ]);
  assert.equal(res.statusCode, 409);
  assert.equal(await stock(2), 50);
  assert.equal((await db.selectFrom("orders").selectAll().execute()).length, 0);
});

test("{w_t_token}", async () => {
  const res = await order({}, "key-0004", [{ product_id: 2, quantity: 1 }]);
  assert.equal(res.statusCode, 401);
  assert.equal(res.headers["content-type"], "application/problem+json; charset=utf-8");
});

test("{w_t_pages}", async () => {
  const seen: number[] = [];
  let url = "/products?limit=2";
  for (;;) {
    const body = (await app.inject({ url })).json();
    seen.push(...body.data.map((p: { id: number }) => p.id));
    if (!body.next_cursor) break;
    url = `/products?limit=2&cursor=${body.next_cursor}`;
  }
  assert.deepEqual(seen, [2, 4, 3, 5, 1]);
});
''',
    "Dockerfile": '''FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM node:22-slim
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY package.json schema.sql ./
COPY src ./src
USER node
EXPOSE 3000
HEALTHCHECK --interval=5s --timeout=2s \\
  CMD node -e "fetch('http://localhost:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"
CMD ["node", "src/server.ts"]
''',
    "compose.yaml": '''name: shop

services:
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: shop
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: shop
    volumes:
      - db-data:/var/lib/postgresql
      - ./schema.sql:/docker-entrypoint-initdb.d/schema.sql:ro
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "shop", "-d", "shop"]
      interval: 2s
      retries: 15

  redis:
    image: redis:8
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 2s
      retries: 15

  app:
    build: .
    image: shop-api
    ports:
      - "3000:3000"
    environment: &env
      DATABASE_URL: postgres://shop:secret@db:5432/shop
      REDIS_URL: redis://redis:6379
    depends_on: &ready
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

  worker:
    image: shop-api
    command: ["node", "src/worker.ts"]
    environment: *env
    depends_on: *ready
    # the worker serves no HTTP, so the image's health check does not apply
    healthcheck:
      disable: true

volumes:
  db-data:
''',
}


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    subprocess.run(["redis-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("psql shop -q -c 'CREATE DATABASE shop_test'")
    s.run("npx tsc")
    s.lines.clear()
    s.note(t["w_s_tree"])
    s.run("ls -A src test; ls --hide=node_modules", shown="ls src test; ls")
    s.save(folder / "tree.sh")
    s.note(t["w_s_test"])
    s.run("npm test --silent 2>&1 | grep -v '^$\\|duration_ms' | sed -E 's/\\(([0-9.]+)ms\\)/(…ms)/'",
          shown="npm test")
    s.save(folder / "test.sh")

    subprocess.run(["npm", "install", "--package-lock-only", "--no-audit", "--no-fund", "-q"], cwd=folder,
                   check=True, capture_output=True, env=os.environ)
    shutil.copy("/root/.ccr/ca-bundle.crt", folder / ".ccr-ca.crt")
    lines = []
    for line in (folder / "Dockerfile").read_text().split("\n"):
        lines.append(line)
        if line.startswith("FROM node"):
            lines += ["COPY .ccr-ca.crt /tmp/ccr-ca.crt", "ENV NODE_EXTRA_CA_CERTS=/tmp/ccr-ca.crt"]
    (folder / "Dockerfile.ccr").write_text("\n".join(lines))
    proxy = os.environ.get("HTTPS_PROXY", "")
    s.note(t["w_s_build"])
    s.run(f"docker build -q -f Dockerfile.ccr --network host --build-arg HTTPS_PROXY={proxy} "
          f"--build-arg https_proxy={proxy} -t shop-api . > /dev/null 2>&1 && "
          "docker image ls shop-api --format '{{.Repository}}:{{.Tag}}  {{.Size}}'",
          shown="docker build -t shop-api .\n$ docker image ls shop-api")
    subprocess.run("docker compose down -v", shell=True, cwd=folder, capture_output=True)
    s.note(t["w_s_up"])
    s.run("docker compose up -d --wait 2>&1 | grep -E '(Started|Healthy) *$' | sed -E 's/^ *//; s/ *$//' "
          "| awk '!seen[$0]++'", shown="docker compose up -d --wait")
    s.run("docker compose ps --format 'table {{.Service}}\\t{{.Status}}'")
    s.save(folder / "docker.sh")

    j = "-H 'content-type: application/json'"
    user = '{"email":"sara@example.com","password":"a long password"}'
    auth = "-H \"authorization: Bearer $TOKEN\""
    real = "-H \"authorization: Bearer $(cat .token)\""
    s.note(t["w_s_register"])
    s.run(f"curl -s localhost:3000/auth/register {j} -d '{user}' | jq -c")
    s.note(t["w_s_login"])
    s.run(f"curl -s localhost:3000/auth/login {j} -d '{user}' | jq -r .token > .token",
          shown=f"TOKEN=$(curl -s localhost:3000/auth/login {j} -d '{user}' | jq -r .token)")
    s.note(t["w_s_page"])
    out = s.run("curl -s 'localhost:3000/products?limit=2' | jq -c")
    cursor = __import__("json").loads(out)["next_cursor"]
    s.note(t["w_s_next"])
    s.run(f"curl -s 'localhost:3000/products?limit=2&cursor={cursor}' | jq -c '.data[].name, .next_cursor'")
    body = '{"items":[{"product_id":1,"quantity":2},{"product_id":2,"quantity":4}]}'
    post = "curl -s -i localhost:3000/orders {j} {a} -H 'idempotency-key: order-0001' -d '{b}' " \
           "| grep -iE '^HTTP|^idempotent|^\\{{' | sed 's/\\r//'"
    s.note(t["w_s_order"])
    s.run(post.format(j=j, a=real, b=body), shown=post.format(j=j, a=auth, b=body))
    s.note(t["w_s_retry"])
    s.run(post.format(j=j, a=real, b=body), shown=post.format(j=j, a=auth, b=body))
    s.note(t["w_s_short"])
    short = '{"items":[{"product_id":1,"quantity":4}]}'
    p2 = f"curl -s localhost:3000/orders {j} AUTH -H 'idempotency-key: order-0002' -d '{short}' | jq -c"
    s.run(p2.replace("AUTH", real), shown=p2.replace("AUTH", auth))
    s.note(t["w_s_anon"])
    s.run(f"curl -s localhost:3000/orders {j} -H 'idempotency-key: order-0003' -d '{short}' | jq -c")
    s.note(t["w_s_guess"])
    bad = '{"email":"sara@example.com","password":"guess"}'
    s.run(f"for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w '%{{http_code}} ' localhost:3000/auth/login {j} "
          f"-d '{bad}'; done; echo")
    s.save(folder / "journey.sh")

    s.note(t["w_s_metrics"])
    s.run("curl -s localhost:3000/metrics | grep '^http_requests_total'")
    s.note(t["w_s_worker"])
    s.run("docker compose logs worker --no-log-prefix", shown="docker compose logs worker")
    s.note(t["w_s_logs"])
    s.run("docker compose logs app --no-log-prefix | grep '\"url\":\"/orders\"' | head -1 "
          "| jq -c '{level, msg, method: .req.method, url: .req.url}'", shown="docker compose logs app")
    s.note(t["w_s_down"])
    s.run("docker compose down -v 2>&1 | grep -E 'Removed' | sed -E 's/^ *//'", shown="docker compose down -v")
    s.save(folder / "ops.sh")
    for name in (".ccr-ca.crt", "Dockerfile.ccr", ".token"):
        (folder / name).unlink(missing_ok=True)


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
