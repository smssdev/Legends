"""Writes the examples of Book 3 (Node edition), the chapter "Authentication and Authorization".
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start)

A small Fastify API with users and orders in PostgreSQL (Kysely): passwords hashed with scrypt from
node:crypto, sessions as random tokens stored only as their SHA-256, a preHandler that authenticates, roles
and ownership checks, a rate limit on login, a JWT made by hand to show what is inside one, and tests with
app.inject. Every request is made with curl against the running server; transcripts are saved as *.sh.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent.parent
sys.path.insert(0, str(B3))
from rec import CLEAN, Server, Session, fill  # noqa: E402

URL = "postgres://bit:secret@localhost:5432/shop"
BASE = "localhost:3000"

T = {
    "en": dict(
        w_sara="Sara", w_omar="Omar", w_lina="Lina", w_admin="Admin",
        w_p_unauth="Not signed in", w_p_unauth_detail="Send a valid token: Authorization: Bearer <token>.",
        w_p_login="Email or password is wrong", w_p_forbidden="Not allowed",
        w_p_forbidden_detail="This needs the {role} role.", w_p_not_found="Not found",
        w_p_no_order="There is no order {id}.", w_p_taken="Email already registered",
        w_p_invalid="Invalid body", w_p_limit="Too many attempts",
        w_p_limit_detail="Try again in {seconds} seconds.", w_p_server="Server error",
        w_c_cost="N = 2^15: tens of milliseconds and 32 MB per hash, slow on purpose; raise it as computers get faster",
        w_c_salt="a new random salt for every hash: the same password never gives the same hash",
        w_c_format="algorithm, cost, salt and key in one string: old hashes still verify after the cost changes",
        w_c_constant="compares every byte, so the time taken does not reveal where the first difference is",
        w_c_token="32 random bytes: impossible to guess, and meaningless without the database",
        w_c_digest="only the hash is stored: a leaked sessions table opens no account",
        w_c_bearer="Authorization: Bearer <token>",
        w_c_role="authorization: the user is known; may they do this?",
        w_c_dummy="an unknown email still costs one hash, so the response time does not reveal which emails exist",
        w_c_same="the same answer for a wrong email and a wrong password",
        w_c_limit="5 attempts a minute per address and email, counted before the password is checked",
        w_c_owner="someone else's order is 'not found', not 'forbidden': its existence is not revealed",
        w_c_all="exercise 4: sign out on every device",
        w_c_jwt_sign="a JWT: header and payload in base64url, then an HMAC of both with the server's secret",
        w_c_jwt_read="anyone can read the payload: it is encoded, not encrypted",
        w_c_jwt_tamper="change the payload, keep the signature",
        w_d_hash1="hash 1", w_d_hash2="hash 2", w_d_right="right password:", w_d_wrong="wrong password:",
        w_d_took="one hash took", w_d_token="token:", w_d_payload="payload, read without the key:",
        w_d_valid="signature valid:", w_d_tampered="tampered token valid:",
        w_t_register="registers, signs in and reads /me", w_t_401="refuses /me without a token",
        w_t_403="refuses the admin list to a customer", w_t_404="hides other customers' orders",
        w_t_logout="a token stops working after sign-out",
        w_s_hash="Two hashes of the same password", w_s_register="Registering",
        w_s_twice="The same email again", w_s_short="A password that is too short",
        w_s_login="Signing in", w_s_wrong="A wrong password, and an unknown email: the same answer",
        w_s_noauth="Without a token", w_s_me="With the token",
        w_s_omar="Omar signs in", w_s_own="His own orders", w_s_other="Sara's order",
        w_s_admin_only="The admin list, as Omar", w_s_as_admin="The admin list, as an admin",
        w_s_logout="Signing out", w_s_after="The same token afterwards",
        w_s_stored="What the database keeps", w_s_limit="Six wrong passwords in a row",
        w_s_jwt="Inside a JWT", w_s_test="The tests", w_s_all="Signed in on two devices, then out of both",
    ),
    "ar": dict(
        w_sara="سارة", w_omar="عمر", w_lina="لينا", w_admin="المدير",
        w_p_unauth="لم تسجّل الدخول", w_p_unauth_detail="أرسل رمزاً صالحاً: Authorization: Bearer <token>.",
        w_p_login="البريد أو كلمة المرور خطأ", w_p_forbidden="غير مسموح",
        w_p_forbidden_detail="هذا يحتاج الدور {role}.", w_p_not_found="غير موجود",
        w_p_no_order="لا يوجد طلب {id}.", w_p_taken="البريد مسجّل من قبل",
        w_p_invalid="جسم غير صالح", w_p_limit="محاولات كثيرة",
        w_p_limit_detail="حاول مرة أخرى بعد {seconds} ثانية.", w_p_server="خطأ في الخادم",
        w_c_cost="N = 2^15: عشرات المللي ثواني و32 MB لكل تجزئة، بطء مقصود؛ ارفعه كلما أسرعت الحواسيب",
        w_c_salt="ملح عشوائي جديد لكل تجزئة: كلمة المرور نفسها لا تعطي التجزئة نفسها أبداً",
        w_c_format="الخوارزمية والكلفة والملح والمفتاح في نص واحد: التجزئات القديمة تُتحقق بعد تغيير الكلفة",
        w_c_constant="تقارن كل بايت، فلا يكشف الوقت المستغرق أين أول اختلاف",
        w_c_token="32 بايتاً عشوائياً: مستحيل تخمينها، ولا معنى لها بلا قاعدة البيانات",
        w_c_digest="تُحفظ التجزئة وحدها: جدول جلسات مسرّب لا يفتح أي حساب",
        w_c_bearer="Authorization: Bearer <token>",
        w_c_role="التفويض: المستخدم معروف؛ فهل يجوز له هذا؟",
        w_c_dummy="البريد المجهول يكلّف تجزئة أيضاً، فلا يكشف زمن الاستجابة أي البُرد موجود",
        w_c_same="الجواب نفسه لبريد خطأ ولكلمة مرور خطأ",
        w_c_limit="5 محاولات في الدقيقة لكل عنوان وبريد، تُعدّ قبل فحص كلمة المرور",
        w_c_owner="طلب غيرك «غير موجود» لا «غير مسموح»: لا يُكشف وجوده",
        w_c_all="التمرين 4: الخروج من كل الأجهزة",
        w_c_jwt_sign="JWT: الرأس والحمولة بـ base64url، ثم HMAC لهما بسر الخادم",
        w_c_jwt_read="أي أحد يقرأ الحمولة: إنها مرمّزة لا مشفّرة",
        w_c_jwt_tamper="غيّر الحمولة، وأبقِ التوقيع",
        w_d_hash1="التجزئة 1", w_d_hash2="التجزئة 2", w_d_right="كلمة المرور الصحيحة:",
        w_d_wrong="كلمة مرور خطأ:", w_d_took="استغرقت التجزئة الواحدة", w_d_token="الرمز:",
        w_d_payload="الحمولة، مقروءة بلا المفتاح:", w_d_valid="التوقيع صالح:",
        w_d_tampered="الرمز المعدّل صالح:",
        w_t_register="يسجّل ويدخل ويقرأ /me", w_t_401="يرفض /me بلا رمز",
        w_t_403="يرفض قائمة المدير لزبون", w_t_404="يخفي طلبات الزبائن الآخرين",
        w_t_logout="يتوقف الرمز عن العمل بعد الخروج",
        w_s_hash="تجزئتان لكلمة المرور نفسها", w_s_register="التسجيل",
        w_s_twice="البريد نفسه مرة أخرى", w_s_short="كلمة مرور أقصر من اللازم",
        w_s_login="تسجيل الدخول", w_s_wrong="كلمة مرور خطأ، وبريد مجهول: الجواب نفسه",
        w_s_noauth="بلا رمز", w_s_me="بالرمز",
        w_s_omar="عمر يسجّل الدخول", w_s_own="طلباته هو", w_s_other="طلب سارة",
        w_s_admin_only="قائمة المدير، بصفة عمر", w_s_as_admin="قائمة المدير، بصفة مدير",
        w_s_logout="تسجيل الخروج", w_s_after="الرمز نفسه بعدها",
        w_s_stored="ما تحفظه قاعدة البيانات", w_s_limit="ست كلمات مرور خطأ متتالية",
        w_s_jwt="داخل JWT", w_s_test="الاختبارات", w_s_all="دخول من جهازين، ثم خروج من كليهما",
    ),
}

FILES = {
    ".env": f"DATABASE_URL={URL}\n",
    "package.json": '''{
  "name": "bit-shop-auth",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node --env-file=.env src/server.ts",
    "migrate": "node --env-file=.env src/migrate.ts",
    "db:types": "kysely-codegen --env-file=.env --type-mapping '{\\"int8\\":\\"number\\"}' --out-file src/db-types.ts",
    "check": "tsc",
    "test": "node --env-file=.env --test --test-reporter=spec"
  },
  "dependencies": {
    "@fastify/rate-limit": "^11.2.2",
    "fastify": "^5.12.8",
    "fastify-type-provider-zod": "^7.0.0",
    "kysely": "^0.29.9",
    "pg": "^8.23.1",
    "zod": "^4.6.7"
  },
  "devDependencies": {
    "@types/node": "^22.20.5",
    "@types/pg": "^8.23.1",
    "kysely-codegen": "^0.20.0",
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
  "include": ["src", "migrations", "demos"]
}
''',
    "migrations/2026_11_08_001_users.ts": '''import { type Kysely, sql } from "kysely";

export async function up(db: Kysely<unknown>): Promise<void> {
  await db.schema
    .createTable("users")
    .addColumn("id", "bigint", (c) => c.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("email", "text", (c) => c.notNull())
    .addColumn("name", "text", (c) => c.notNull())
    .addColumn("password_hash", "text", (c) => c.notNull())
    .addColumn("role", "text", (c) =>
      c.notNull().defaultTo("customer").check(sql`role IN ('customer', 'admin')`))
    .addColumn("created_at", "timestamptz", (c) => c.notNull().defaultTo(sql`now()`))
    .execute();
  // one account per email, whatever its capitals
  await db.schema
    .createIndex("users_email_key")
    .on("users")
    .unique()
    .expression(sql`lower(email)`)
    .execute();

  await db.schema
    .createTable("sessions")
    .addColumn("token_hash", "text", (c) => c.primaryKey())
    .addColumn("user_id", "bigint", (c) =>
      c.notNull().references("users.id").onDelete("cascade"))
    .addColumn("created_at", "timestamptz", (c) => c.notNull().defaultTo(sql`now()`))
    .addColumn("expires_at", "timestamptz", (c) => c.notNull())
    .execute();
  await db.schema
    .createIndex("sessions_user_id_idx").on("sessions").column("user_id").execute();

  await db.schema
    .createTable("orders")
    .addColumn("id", "bigint", (c) => c.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("user_id", "bigint", (c) => c.notNull().references("users.id"))
    .addColumn("total", "integer", (c) => c.notNull())
    .addColumn("created_at", "timestamptz", (c) => c.notNull().defaultTo(sql`now()`))
    .execute();
  await db.schema
    .createIndex("orders_user_id_idx").on("orders").column("user_id").execute();
}

export async function down(db: Kysely<unknown>): Promise<void> {
  for (const table of ["orders", "sessions", "users"]) {
    await db.schema.dropTable(table).execute();
  }
}
''',
    "src/migrate.ts": '''import { promises as fs } from "node:fs";
import path from "node:path";
import { Kysely, PostgresDialect } from "kysely";
import { FileMigrationProvider, Migrator } from "kysely/migration";
import pg from "pg";

const db = new Kysely<unknown>({
  dialect: new PostgresDialect({
    pool: new pg.Pool({ connectionString: process.env.DATABASE_URL }),
  }),
});
const migrator = new Migrator({
  db,
  provider: new FileMigrationProvider({
    fs,
    path,
    migrationFolder: path.join(import.meta.dirname, "../migrations"),
  }),
});
const { error, results } = await migrator.migrateToLatest();
for (const r of results ?? []) console.log(`${r.status} ${r.migrationName}`);
if (error) {
  console.error("migration failed:", error);
  process.exitCode = 1;
}
await db.destroy();
''',
    "src/db.ts": '''import { Kysely, PostgresDialect } from "kysely";
import pg from "pg";
import type { DB } from "./db-types.ts";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

export const db = new Kysely<DB>({
  dialect: new PostgresDialect({
    pool: new pg.Pool({ connectionString: process.env.DATABASE_URL }),
  }),
});
''',
    "src/password.ts": '''import { randomBytes, scrypt, timingSafeEqual } from "node:crypto";

// {w_c_cost}
const COST = 2 ** 15;

function derive(password: string, salt: Buffer, cost: number) {
  return new Promise<Buffer>((resolve, reject) => {
    const options = { N: cost, r: 8, p: 1, maxmem: 64 * 1024 * 1024 };
    scrypt(password.normalize("NFKC"), salt, 32, options, (error, key) =>
      error ? reject(error) : resolve(key));
  });
}

export async function hashPassword(password: string) {
  // {w_c_salt}
  const salt = randomBytes(16);
  const key = await derive(password, salt, COST);
  // {w_c_format}
  return ["scrypt", COST, salt.toString("base64url"), key.toString("base64url")].join("$");
}

export async function verifyPassword(password: string, stored: string) {
  const [, cost, salt, key] = stored.split("$");
  const expected = Buffer.from(key ?? "", "base64url");
  const actual = await derive(password, Buffer.from(salt ?? "", "base64url"), Number(cost));
  // {w_c_constant}
  return timingSafeEqual(actual, expected);
}
''',
    "src/sessions.ts": '''import { createHash, randomBytes } from "node:crypto";
import { sql } from "kysely";
import { db } from "./db.ts";

const digest = (token: string) => createHash("sha256").update(token).digest("hex");

export async function startSession(userId: number) {
  // {w_c_token}
  const token = randomBytes(32).toString("base64url");
  await db
    .insertInto("sessions")
    // {w_c_digest}
    .values({
      token_hash: digest(token),
      user_id: userId,
      expires_at: sql`now() + interval '30 days'`,
    })
    .execute();
  return token;
}

export async function userForToken(token: string) {
  return db
    .selectFrom("sessions")
    .innerJoin("users", "users.id", "sessions.user_id")
    .select(["users.id", "users.email", "users.name", "users.role"])
    .where("sessions.token_hash", "=", digest(token))
    .where("sessions.expires_at", ">", sql<Date>`now()`)
    .executeTakeFirst();
}

export async function endSession(token: string) {
  await db.deleteFrom("sessions").where("token_hash", "=", digest(token)).execute();
}
''',
    "src/problem.ts": '''// Errors as Problem Details, as in Chapter 3, with only the problems this API needs.
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
  unauthenticated: () => new Problem(401, "{w_p_unauth}", "{w_p_unauth_detail}"),
  badLogin: () => new Problem(401, "{w_p_login}"),
  forbidden: (role: string) =>
    new Problem(403, "{w_p_forbidden}", say("{w_p_forbidden_detail}", { role })),
  noOrder: (id: number) =>
    new Problem(404, "{w_p_not_found}", say("{w_p_no_order}", { id })),
  emailTaken: () => new Problem(409, "{w_p_taken}"),
  invalid: (errors: { field: string; message: string }[]) =>
    new Problem(422, "{w_p_invalid}", undefined, { errors }),
  tooMany: (seconds: number) =>
    new Problem(429, "{w_p_limit}", say("{w_p_limit_detail}", { seconds })),
  server: () => new Problem(500, "{w_p_server}"),
};
''',
    "src/auth.ts": '''import type { FastifyRequest } from "fastify";
import { problems } from "./problem.ts";
import { userForToken } from "./sessions.ts";

export type User = NonNullable<Awaited<ReturnType<typeof userForToken>>>;
export type Role = "customer" | "admin";

declare module "fastify" {
  interface FastifyRequest {
    user?: User;
    token?: string;
  }
}

// Authentication: who is calling? ({w_c_bearer})
export async function authenticate(request: FastifyRequest) {
  const [scheme, token] = (request.headers.authorization ?? "").split(" ");
  const user = scheme === "Bearer" && token ? await userForToken(token) : undefined;
  if (!user) throw problems.unauthenticated();
  request.user = user;
  request.token = token;
}

// {w_c_role}
export function requireRole(role: Role) {
  return async (request: FastifyRequest) => {
    if (request.user?.role !== role) throw problems.forbidden(role);
  };
}

export function currentUser(request: FastifyRequest): User {
  if (!request.user) throw problems.unauthenticated();
  return request.user;
}
''',
    "src/routes/auth.ts": '''import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { sql } from "kysely";
import { z } from "zod";
import { authenticate, currentUser } from "../auth.ts";
import { db } from "../db.ts";
import { hashPassword, verifyPassword } from "../password.ts";
import { problems } from "../problem.ts";
import { endSession, startSession } from "../sessions.ts";

const UserOut = z.object({
  id: z.number(),
  email: z.string(),
  name: z.string(),
  role: z.string(),
});
const Email = z.email().max(254).toLowerCase();
const Login = z.strictObject({ email: Email, password: z.string().max(128) });
// {w_c_dummy}
const DUMMY = await hashPassword("not anyone's password");

export const authRoutes: FastifyPluginAsyncZod = async (app) => {
  app.post(
    "/auth/register",
    {
      schema: {
        body: z.strictObject({
          email: Email,
          name: z.string().trim().min(1).max(100),
          password: z.string().min(12).max(128),
        }),
        response: { 201: UserOut },
      },
    },
    async (request, reply) => {
      const { email, name, password } = request.body;
      const user = await db
        .insertInto("users")
        .values({ email, name, password_hash: await hashPassword(password) })
        .onConflict((c) => c.expression(sql`lower(email)`).doNothing())
        .returning(["id", "email", "name", "role"])
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
            `${request.ip}:${(request.body as { email?: string }).email}`,
        },
      },
      schema: {
        body: Login,
        response: { 200: z.object({ token: z.string(), expires_in: z.number() }) },
      },
    },
    async (request) => {
      const { email, password } = request.body;
      const user = await db
        .selectFrom("users")
        .select(["id", "password_hash"])
        .where(sql`lower(email)`, "=", email)
        .executeTakeFirst();
      const ok = await verifyPassword(password, user?.password_hash ?? DUMMY);
      // {w_c_same}
      if (!user || !ok) throw problems.badLogin();
      return { token: await startSession(user.id), expires_in: 30 * 24 * 3600 };
    },
  );

  app.post("/auth/logout", { onRequest: authenticate }, async (request, reply) => {
    await endSession(request.token ?? "");
    return reply.code(204).send();
  });

  // {w_c_all}
  app.post("/auth/logout-all", { onRequest: authenticate }, async (request, reply) => {
    await db.deleteFrom("sessions").where("user_id", "=", currentUser(request).id).execute();
    return reply.code(204).send();
  });

  app.get(
    "/me",
    { onRequest: authenticate, schema: { response: { 200: UserOut } } },
    async (request) => currentUser(request),
  );
};
''',
    "src/routes/orders.ts": '''import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import { authenticate, currentUser, requireRole } from "../auth.ts";
import { db } from "../db.ts";
import { problems } from "../problem.ts";

export const orderRoutes: FastifyPluginAsyncZod = async (app) => {
  // every route in this plugin needs a signed-in user
  app.addHook("onRequest", authenticate);

  app.get("/orders", async (request) =>
    db
      .selectFrom("orders")
      .select(["id", "total"])
      .where("user_id", "=", currentUser(request).id)
      .orderBy("id")
      .execute(),
  );

  app.get(
    "/orders/:id",
    { schema: { params: z.object({ id: z.coerce.number().int() }) } },
    async (request) => {
      const user = currentUser(request);
      const order = await db
        .selectFrom("orders")
        .selectAll()
        .where("id", "=", request.params.id)
        .executeTakeFirst();
      // {w_c_owner}
      if (!order || (order.user_id !== user.id && user.role !== "admin")) {
        throw problems.noOrder(request.params.id);
      }
      return order;
    },
  );

  app.get("/admin/users", { preHandler: requireRole("admin") }, async () =>
    db.selectFrom("users").select(["id", "email", "role"]).orderBy("id").execute(),
  );
};
''',
    "src/app.ts": '''import Fastify, { type FastifyError } from "fastify";
import rateLimit from "@fastify/rate-limit";
import {
  hasZodFastifySchemaValidationErrors,
  serializerCompiler,
  validatorCompiler,
} from "fastify-type-provider-zod";
import { Problem, problems } from "./problem.ts";
import { authRoutes } from "./routes/auth.ts";
import { orderRoutes } from "./routes/orders.ts";

export async function buildApp() {
  const app = Fastify();
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);
  // only routes that ask for it are limited (here: login)
  await app.register(rateLimit, { global: false });

  app.setErrorHandler((error: FastifyError, request, reply) => {
    let problem: Problem;
    if (error instanceof Problem) {
      problem = error;
    } else if (hasZodFastifySchemaValidationErrors(error)) {
      problem = problems.invalid(
        error.validation.map((issue) => ({
          field: String(issue.instancePath).split("/").filter(Boolean).join("."),
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

  await app.register(authRoutes);
  await app.register(orderRoutes);
  app.get("/ready", async () => ({ ready: true }));
  return app;
}
''',
    "src/server.ts": '''import { buildApp } from "./app.ts";

const app = await buildApp();
await app.listen({ port: 3000 });
console.log("Listening on http://localhost:3000");
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => app.close());
''',
    "src/seed.ts": '''import { db } from "./db.ts";
import { hashPassword } from "./password.ts";

// Two customers with orders, and an admin. Real passwords are never written in code;
// these exist only on a developer's machine.
const people = [
  { email: "sara@example.com", name: "{w_sara}", role: "customer", totals: [45000, 6000] },
  { email: "omar@example.com", name: "{w_omar}", role: "customer", totals: [12000] },
  { email: "admin@example.com", name: "{w_admin}", role: "admin", totals: [] },
];
for (const p of people) {
  const password_hash = await hashPassword(`${p.email.split("@")[0]}-password-2026`);
  const { id } = await db
    .insertInto("users")
    .values({ email: p.email, name: p.name, role: p.role, password_hash })
    .returning("id")
    .executeTakeFirstOrThrow();
  for (const total of p.totals) {
    await db.insertInto("orders").values({ user_id: id, total }).execute();
  }
}
await db.destroy();
''',
    "src/auth.test.ts": '''import assert from "node:assert/strict";
import { after, test } from "node:test";
import { buildApp } from "./app.ts";
import { db } from "./db.ts";

const app = await buildApp();
after(() => Promise.all([app.close(), db.destroy()]));

async function signIn(email: string, password: string) {
  const res = await app.inject({
    method: "POST",
    url: "/auth/login",
    payload: { email, password },
  });
  return res.json().token as string;
}
const as = (token: string) => ({ authorization: `Bearer ${token}` });

test("{w_t_register}", async () => {
  const email = `test-${Date.now()}@example.com`;
  const password = "a long test password";
  const created = await app.inject({
    method: "POST",
    url: "/auth/register",
    payload: { email, name: "Test", password },
  });
  assert.equal(created.statusCode, 201);
  const me = await app.inject({ url: "/me", headers: as(await signIn(email, password)) });
  assert.equal(me.json().email, email);
});

test("{w_t_401}", async () => {
  assert.equal((await app.inject({ url: "/me" })).statusCode, 401);
});

test("{w_t_403}", async () => {
  const omar = await signIn("omar@example.com", "omar-password-2026");
  const res = await app.inject({ url: "/admin/users", headers: as(omar) });
  assert.equal(res.statusCode, 403);
});

test("{w_t_404}", async () => {
  const omar = await signIn("omar@example.com", "omar-password-2026");
  const res = await app.inject({ url: "/orders/1", headers: as(omar) });
  assert.equal(res.statusCode, 404);
});

test("{w_t_logout}", async () => {
  const sara = await signIn("sara@example.com", "sara-password-2026");
  await app.inject({ method: "POST", url: "/auth/logout", headers: as(sara) });
  assert.equal((await app.inject({ url: "/me", headers: as(sara) })).statusCode, 401);
});
''',
    "demos/hash.ts": '''import { hashPassword, verifyPassword } from "../src/password.ts";

const a = await hashPassword("correct horse battery staple");
const b = await hashPassword("correct horse battery staple");
console.log("{w_d_hash1}", a);
console.log("{w_d_hash2}", b);
console.log("{w_d_right}", await verifyPassword("correct horse battery staple", a));
console.log("{w_d_wrong}", await verifyPassword("correct horse battery stapler", a));
const start = performance.now();
await hashPassword("correct horse battery staple");
console.log("{w_d_took}", Math.round(performance.now() - start), "ms");
''',
    "demos/jwt.ts": '''import { createHmac, timingSafeEqual } from "node:crypto";

const secret = "a secret only the server knows";
const b64 = (value: object) => Buffer.from(JSON.stringify(value)).toString("base64url");
const sign = (data: string) => createHmac("sha256", secret).update(data).digest("base64url");

// {w_c_jwt_sign}
const header = b64({ alg: "HS256", typ: "JWT" });
const payload = b64({ sub: 2, role: "customer", exp: 1795000000 });
const token = `${header}.${payload}.${sign(`${header}.${payload}`)}`;
console.log("{w_d_token}", token);

// {w_c_jwt_read}
const read = (part: string) => JSON.parse(Buffer.from(part, "base64url").toString());
console.log("{w_d_payload}", read(token.split(".")[1] ?? ""));

const valid = (jwt: string) => {
  const [h, p, signature = ""] = jwt.split(".");
  const expected = Buffer.from(sign(`${h}.${p}`));
  const given = Buffer.from(signature);
  return given.length === expected.length && timingSafeEqual(given, expected);
};
console.log("{w_d_valid}", valid(token));
// {w_c_jwt_tamper}
const forged = b64({ sub: 2, role: "admin", exp: 1795000000 });
console.log("{w_d_tampered}", valid(`${header}.${forged}.${token.split(".")[2]}`));
''',
}


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("npm run migrate --silent && npm run db:types --silent > /dev/null 2>&1")
    s.run("npx tsc")
    s.run("node --env-file=.env src/seed.ts")
    s.lines.clear()
    s.note(t["w_s_hash"])
    s.run("node demos/hash.ts")
    s.save(folder / "hash.sh")
    s.note(t["w_s_jwt"])
    s.run("node demos/jwt.ts")
    s.save(folder / "jwt.sh")

    j = "-H 'content-type: application/json'"
    login = "curl -s localhost:3000/auth/login " + j + " -d '{{\"email\":\"{}\",\"password\":\"{}\"}}'"
    with Server("node --env-file=.env src/server.ts", folder, f"http://{BASE}/ready"):
        s.note(t["w_s_register"])
        s.run(f"curl -s -i localhost:3000/auth/register {j} -d '{{\"email\":\"Lina@Example.com\","
              f"\"name\":\"{t['w_lina']}\",\"password\":\"a long and silly sentence\"}}'"
              " | grep -v -i '^date\\|^connection\\|^keep-alive\\|^content-length'",
              shown=f"curl -s -i localhost:3000/auth/register {j} -d '{{\"email\":\"Lina@Example.com\","
                    f"\"name\":\"{t['w_lina']}\",\"password\":\"a long and silly sentence\"}}'")
        s.note(t["w_s_twice"])
        s.run(f"curl -s localhost:3000/auth/register {j} -d '{{\"email\":\"lina@example.com\","
              f"\"name\":\"{t['w_lina']}\",\"password\":\"another long sentence\"}}' | jq")
        s.note(t["w_s_short"])
        s.run(f"curl -s localhost:3000/auth/register {j} -d '{{\"email\":\"sam@example.com\","
              f"\"name\":\"Sam\",\"password\":\"short\"}}' | jq")
        s.save(folder / "register.sh")

        s.note(t["w_s_login"])
        s.run(login.format("lina@example.com", "a long and silly sentence") + " | jq")
        s.note(t["w_s_wrong"])
        s.run(login.format("lina@example.com", "a wrong sentence") + " | jq")
        s.run(login.format("nobody@example.com", "a wrong sentence") + " | jq")
        s.save(folder / "login.sh")

        s.run(login.format("lina@example.com", "a long and silly sentence") + " | jq -r .token > .token")
        s.lines.clear()
        s.note(t["w_s_noauth"])
        s.run("curl -s localhost:3000/me | jq")
        s.note(t["w_s_me"])
        s.add("$ TOKEN=$(curl -s localhost:3000/auth/login " + j +
              " -d '{\"email\":\"lina@example.com\",\"password\":\"a long and silly sentence\"}' | jq -r .token)")
        s.run('curl -s localhost:3000/me -H "authorization: Bearer $(cat .token)" | jq',
              shown='curl -s localhost:3000/me -H "authorization: Bearer $TOKEN" | jq')
        s.save(folder / "me.sh")

        s.note(t["w_s_omar"])
        s.run(login.format("omar@example.com", "omar-password-2026") + " | jq -r .token > .omar", check=True)
        s.lines.pop()
        s.add("$ OMAR=$(curl -s localhost:3000/auth/login " + j +
              " -d '{\"email\":\"omar@example.com\",\"password\":\"omar-password-2026\"}' | jq -r .token)")
        s.note(t["w_s_own"])
        s.run('curl -s localhost:3000/orders -H "authorization: Bearer $(cat .omar)" | jq -c',
              shown='curl -s localhost:3000/orders -H "authorization: Bearer $OMAR" | jq -c')
        s.note(t["w_s_other"])
        s.run('curl -s localhost:3000/orders/1 -H "authorization: Bearer $(cat .omar)" | jq',
              shown='curl -s localhost:3000/orders/1 -H "authorization: Bearer $OMAR" | jq')
        s.note(t["w_s_admin_only"])
        s.run('curl -s localhost:3000/admin/users -H "authorization: Bearer $(cat .omar)" | jq',
              shown='curl -s localhost:3000/admin/users -H "authorization: Bearer $OMAR" | jq')
        s.run(login.format("admin@example.com", "admin-password-2026") + " | jq -r .token > .admin")
        s.lines.pop()
        s.note(t["w_s_as_admin"])
        s.add("$ ADMIN=$(curl -s localhost:3000/auth/login " + j +
              " -d '{\"email\":\"admin@example.com\",\"password\":\"admin-password-2026\"}' | jq -r .token)")
        s.run('curl -s localhost:3000/admin/users -H "authorization: Bearer $(cat .admin)" | jq -c ".[]"',
              shown='curl -s localhost:3000/admin/users -H "authorization: Bearer $ADMIN" | jq -c ".[]"')
        s.save(folder / "authz.sh")

        s.note(t["w_s_logout"])
        s.run('curl -s -o /dev/null -w "%{http_code}\\n" -X POST localhost:3000/auth/logout '
              '-H "authorization: Bearer $(cat .token)"',
              shown='curl -s -o /dev/null -w "%{http_code}\\n" -X POST localhost:3000/auth/logout '
                    '-H "authorization: Bearer $TOKEN"')
        s.note(t["w_s_after"])
        s.run('curl -s localhost:3000/me -H "authorization: Bearer $(cat .token)" | jq .title',
              shown='curl -s localhost:3000/me -H "authorization: Bearer $TOKEN" | jq .title')
        s.note(t["w_s_stored"])
        s.run("psql shop -c 'SELECT email, left(password_hash, 40) AS password_hash FROM users ORDER BY id'")
        s.run("psql shop -c 'SELECT user_id, left(token_hash, 16) AS token_hash, expires_at::date FROM sessions'")
        s.save(folder / "logout.sh")

        s.note(t["w_s_limit"])
        s.run("for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w '%{http_code} ' localhost:3000/auth/login "
              + j + " -d '{\"email\":\"sara@example.com\",\"password\":\"guess number one\"}'; done; echo")
        s.run(login.format("sara@example.com", "guess number seven") + " | jq")
        s.save(folder / "limit.sh")

        # Exercise 4's answer: two devices, one request signs both out.
        for name in ("phone", "laptop"):
            s.run(login.format("omar@example.com", "omar-password-2026") + f" | jq -r .token > .{name}")
        s.lines.clear()
        s.note(t["w_s_all"])
        s.run('curl -s -o /dev/null -w "%{http_code}\\n" -X POST localhost:3000/auth/logout-all '
              '-H "authorization: Bearer $(cat .phone)"',
              shown='curl -s -o /dev/null -w "%{http_code}\\n" -X POST localhost:3000/auth/logout-all '
                    '-H "authorization: Bearer $PHONE"')
        s.run('curl -s -o /dev/null -w "%{http_code}\\n" localhost:3000/me -H "authorization: Bearer $(cat .laptop)"',
              shown='curl -s -o /dev/null -w "%{http_code}\\n" localhost:3000/me -H "authorization: Bearer $LAPTOP"')
        s.save(folder / "answers.sh")

    s.note(t["w_s_test"])
    s.run("npm test --silent 2>&1 | grep -v '^$\\|duration_ms' | sed -E 's/\\(([0-9.]+)ms\\)/(…ms)/'",
          shown="npm test")
    s.save(folder / "test.sh")
    for name in (".token", ".omar", ".admin", ".phone", ".laptop"):
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
    subprocess.run(["npx", "prettier", "--print-width", "84", "--write", "src", "demos", "migrations"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
