"""Writes the examples of Book 3 (Node.js edition), chapter 5 "Data Modelling and Migrations".
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start; npm ci in code/b3)

A Node project per language (<lang>/) on Kysely: migrations run with Kysely's migrator (including a column
added in expand and contract steps), types generated from the real database with kysely-codegen, typed
queries, a type error caught by tsc, and the N+1 problem measured by counting queries.
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
        w_kit="Robot kit", w_wheels="Spare wheels", w_battery="Battery pack", w_cable="USB cable",
        w_sara="Sara", w_omar="Omar", w_lina="Lina",
        w_c_up="up: what this migration adds", w_c_down="down: how to undo it exactly",
        w_c_expand="Step 1, expand: a new column that may be empty, so old code keeps working.",
        w_c_backfill="Step 2: fill the column for every existing row.",
        w_c_contract="Step 3, contract: now every row has a SKU, make it required and unique.",
        w_c_int8="bigint ids as numbers: exact up to 2^53, far more ids than any shop will have",
        w_c_one_place="The connection, in one place; DB describes every table, generated from the database.",
        w_c_log="every query the app sends, counted (and printed with DEBUG_SQL=1)",
        w_c_typed="the result type is built from the selected columns",
        w_c_json="the items as a JSON array, built by PostgreSQL in the same query",
        w_c_n1="One query for the orders, then one more for EACH order: 1 + N.",
        w_c_one="One query, whatever the number of orders.",
        w_c_typo="a column that does not exist",
        w_d_queries="queries", w_d_orders="orders",
        w_s_migrate="Run every migration that has not run yet",
        w_s_table="The table after the three migrations",
        w_s_history="Kysely records what ran, in its own table",
        w_s_down="Undo the last migration, then run it again",
        w_s_codegen="Generate TypeScript types from the real database",
        w_s_typo="tsc knows every table and column",
        w_s_query="A typed query: an order with its customer and items",
        w_s_n1="The same report two ways: count the queries",
    ),
    "ar": dict(
        w_kit="عدة الروبوت", w_wheels="عجلات احتياطية", w_battery="حزمة بطارية", w_cable="كابل USB",
        w_sara="سارة", w_omar="عمر", w_lina="لينا",
        w_c_up="up: ما يضيفه هذا الترحيل", w_c_down="down: كيف يُتراجع عنه بالضبط",
        w_c_expand="الخطوة 1، التوسيع: عمود جديد يجوز أن يكون فارغاً، فيبقى الكود القديم يعمل.",
        w_c_backfill="الخطوة 2: املأ العمود لكل صف موجود.",
        w_c_contract="الخطوة 3، التقليص: الآن لكل صف رمز SKU، فاجعله إلزامياً وفريداً.",
        w_c_int8="أرقام bigint أعداداً: دقيقة حتى 2^53، أكثر بكثير مما سيحتاجه أي متجر",
        w_c_one_place="الاتصال في مكان واحد، وDB يصف كل جدول، مولَّداً من قاعدة البيانات.",
        w_c_log="كل استعلام يرسله التطبيق، معدوداً (ومطبوعاً مع DEBUG_SQL=1)",
        w_c_typed="نوع النتيجة يُبنى من الأعمدة المختارة",
        w_c_json="العناصر مصفوفة JSON تبنيها PostgreSQL في الاستعلام نفسه",
        w_c_n1="استعلام للطلبات، ثم استعلام آخر لكل طلب: 1 + N.",
        w_c_one="استعلام واحد، مهما كان عدد الطلبات.",
        w_c_typo="عمود غير موجود",
        w_d_queries="استعلامات", w_d_orders="طلبات",
        w_s_migrate="شغّل كل ترحيل لم يعمل بعد",
        w_s_table="الجدول بعد الترحيلات الثلاثة",
        w_s_history="يسجّل Kysely ما عمل، في جدول خاص به",
        w_s_down="تراجع عن آخر ترحيل، ثم شغّله مرة أخرى",
        w_s_codegen="ولّد أنواع TypeScript من قاعدة البيانات الحقيقية",
        w_s_typo="يعرف tsc كل جدول وكل عمود",
        w_s_query="استعلام بأنواع: طلب مع عميله وعناصره",
        w_s_n1="التقرير نفسه بطريقتين: عُدّ الاستعلامات",
    ),
}

FILES = {
    "package.json": '''{
  "name": "bit-shop-data",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "migrate": "node --env-file=.env src/migrate.ts",
    "db:types": "kysely-codegen --env-file=.env --type-mapping '{\\"int8\\":\\"number\\"}' --out-file src/db-types.ts",
    "check": "tsc"
  },
  "dependencies": {
    "kysely": "^0.29.9",
    "pg": "^8.23.1"
  },
  "devDependencies": {
    "@types/node": "^22.20.5",
    "@types/pg": "^8.23.1",
    "kysely-codegen": "^0.20.0",
    "typescript": "^7.0.2"
  }
}
''',
    ".env": f"DATABASE_URL={URL}\n",
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
    "migrations/2026_11_01_001_initial.ts": '''import { type Kysely, sql } from "kysely";

// {w_c_up}
export async function up(db: Kysely<unknown>): Promise<void> {
  await db.schema
    .createTable("customers")
    .addColumn("id", "bigint", (c) => c.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("name", "text", (c) => c.notNull())
    .addColumn("email", "text", (c) => c.notNull().unique())
    .addColumn("created_at", "timestamptz", (c) => c.notNull().defaultTo(sql`now()`))
    .execute();

  await db.schema
    .createTable("products")
    .addColumn("id", "bigint", (c) => c.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("name", "text", (c) => c.notNull())
    .addColumn("price", "integer", (c) => c.notNull().check(sql`price > 0`))
    .addColumn("stock", "integer", (c) => c.notNull().defaultTo(0).check(sql`stock >= 0`))
    .execute();

  await db.schema
    .createTable("orders")
    .addColumn("id", "bigint", (c) => c.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("customer_id", "bigint", (c) => c.notNull().references("customers.id"))
    .addColumn("status", "text", (c) =>
      c.notNull().defaultTo("pending")
        .check(sql`status IN ('pending', 'paid', 'shipped', 'cancelled')`))
    .addColumn("created_at", "timestamptz", (c) => c.notNull().defaultTo(sql`now()`))
    .execute();
  await db.schema.createIndex("orders_customer_id_idx").on("orders").column("customer_id").execute();

  await db.schema
    .createTable("order_items")
    .addColumn("order_id", "bigint", (c) => c.notNull().references("orders.id").onDelete("cascade"))
    .addColumn("product_id", "bigint", (c) => c.notNull().references("products.id"))
    .addColumn("quantity", "integer", (c) => c.notNull().check(sql`quantity BETWEEN 1 AND 99`))
    .addColumn("price", "integer", (c) => c.notNull())
    .addPrimaryKeyConstraint("order_items_pkey", ["order_id", "product_id"])
    .execute();
}

// {w_c_down}
export async function down(db: Kysely<unknown>): Promise<void> {
  for (const table of ["order_items", "orders", "products", "customers"]) {
    await db.schema.dropTable(table).execute();
  }
}
''',
    "migrations/2026_11_02_001_product_sku_expand.ts": '''import type { Kysely } from "kysely";

// {w_c_expand}
export async function up(db: Kysely<unknown>): Promise<void> {
  await db.schema.alterTable("products").addColumn("sku", "text").execute();
}

export async function down(db: Kysely<unknown>): Promise<void> {
  await db.schema.alterTable("products").dropColumn("sku").execute();
}
''',
    "migrations/2026_11_03_001_product_sku_contract.ts": '''import { type Kysely, sql } from "kysely";

export async function up(db: Kysely<unknown>): Promise<void> {
  // {w_c_backfill}
  await sql`UPDATE products SET sku = 'BIT-' || lpad(id::text, 4, '0') WHERE sku IS NULL`.execute(db);
  // {w_c_contract}
  await db.schema.alterTable("products").alterColumn("sku", (c) => c.setNotNull()).execute();
  await db.schema.createIndex("products_sku_key").on("products").column("sku").unique().execute();
}

export async function down(db: Kysely<unknown>): Promise<void> {
  await db.schema.dropIndex("products_sku_key").execute();
  await db.schema.alterTable("products").alterColumn("sku", (c) => c.dropNotNull()).execute();
}
''',
    "src/migrate.ts": '''import { promises as fs } from "node:fs";
import path from "node:path";
import { Kysely, PostgresDialect } from "kysely";
import { FileMigrationProvider, Migrator } from "kysely/migration";
import pg from "pg";

const db = new Kysely<unknown>({
  dialect: new PostgresDialect({ pool: new pg.Pool({ connectionString: process.env.DATABASE_URL }) }),
});
const migrator = new Migrator({
  db,
  provider: new FileMigrationProvider({
    fs,
    path,
    migrationFolder: path.join(import.meta.dirname, "../migrations"),
  }),
});

const { error, results } =
  process.argv[2] === "down" ? await migrator.migrateDown() : await migrator.migrateToLatest();
for (const r of results ?? []) {
  console.log(`${r.status.padEnd(7)} ${r.direction.padEnd(4)} ${r.migrationName}`);
}
if (error) {
  console.error("migration failed:", error);
  process.exitCode = 1;
}
if (!results?.length) console.log("nothing to do");
await db.destroy();
''',
    "src/db.ts": '''import { Kysely, PostgresDialect } from "kysely";
import pg from "pg";
import type { DB } from "./db-types.ts";

// {w_c_int8}
pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

// {w_c_one_place}
export let queries = 0; // {w_c_log}
export const db = new Kysely<DB>({
  dialect: new PostgresDialect({ pool: new pg.Pool({ connectionString: process.env.DATABASE_URL }) }),
  log(event) {
    if (event.level === "query") {
      queries++;
      if (process.env.DEBUG_SQL) console.log(event.query.sql, event.query.parameters);
    }
  },
});
''',
    "src/orders.ts": '''import { jsonArrayFrom } from "kysely/helpers/postgres";
import { db } from "./db.ts";

export async function findOrder(id: number) {
  // {w_c_typed}
  return db
    .selectFrom("orders as o")
    .innerJoin("customers as c", "c.id", "o.customer_id")
    .select((eb) => [
      "o.id",
      "o.status",
      "c.name as customer",
      // {w_c_json}
      jsonArrayFrom(
        eb.selectFrom("order_items as i")
          .innerJoin("products as p", "p.id", "i.product_id")
          .select(["p.name", "i.quantity", "i.price"])
          .whereRef("i.order_id", "=", "o.id"),
      ).as("items"),
    ])
    .where("o.id", "=", id)
    .executeTakeFirst();
}

// {w_c_n1}
export async function customerOrdersOneByOne(customerId: number) {
  const orders = await db.selectFrom("orders").select(["id", "status"])
    .where("customer_id", "=", customerId).execute();
  const result = [];
  for (const order of orders) {
    const items = await db.selectFrom("order_items").select(["product_id", "quantity", "price"])
      .where("order_id", "=", order.id).execute();
    result.push({ ...order, items });
  }
  return result;
}

// {w_c_one}
export async function customerOrdersAtOnce(customerId: number) {
  return db
    .selectFrom("orders as o")
    .select((eb) => [
      "o.id",
      "o.status",
      jsonArrayFrom(
        eb.selectFrom("order_items as i").select(["i.product_id", "i.quantity", "i.price"])
          .whereRef("i.order_id", "=", "o.id"),
      ).as("items"),
    ])
    .where("o.customer_id", "=", customerId)
    .execute();
}
''',
    "src/seed.ts": '''import { sql } from "kysely";
import { db } from "./db.ts";

await db.insertInto("customers").values([
  { name: "{w_sara}", email: "sara@example.com" },
  { name: "{w_omar}", email: "omar@example.com" },
  { name: "{w_lina}", email: "lina@example.com" },
]).execute();
await db.insertInto("products").values([
  { name: "{w_kit}", price: 45000, stock: 10, sku: "BIT-0001" },
  { name: "{w_wheels}", price: 6000, stock: 25, sku: "BIT-0002" },
  { name: "{w_battery}", price: 12500, stock: 8, sku: "BIT-0003" },
  { name: "{w_cable}", price: 2500, stock: 80, sku: "BIT-0004" },
]).execute();
// Sara gets 200 orders of 1 to 3 items, for the N+1 measurement.
await sql`INSERT INTO orders (customer_id, status)
          SELECT 1, 'shipped' FROM generate_series(1, 200)`.execute(db);
await sql`INSERT INTO order_items (order_id, product_id, quantity, price)
          SELECT o.id, p.id, 1, p.price FROM orders o JOIN products p ON p.id <= 1 + o.id % 3`.execute(db);
console.log("seeded");
await db.destroy();
''',
    "demos/order.ts": '''import { db } from "../src/db.ts";
import { findOrder } from "../src/orders.ts";

const order = await findOrder(2);
console.log(order);
await db.destroy();
''',
    "demos/typo.ts": '''import { db } from "../src/db.ts";

const rows = await db.selectFrom("products").select(["name", "prise"]).execute(); // {w_c_typo}
console.log(rows[0]?.name.toUpperCase());
''',
    "demos/n-plus-one.ts": '''import * as data from "../src/db.ts";
import { customerOrdersAtOnce, customerOrdersOneByOne } from "../src/orders.ts";

for (const [label, load] of [
  ["one by one", customerOrdersOneByOne],
  ["at once", customerOrdersAtOnce],
] as const) {
  const before = data.queries;
  const start = performance.now();
  const orders = await load(1);
  const ms = Math.round(performance.now() - start);
  console.log(`${label.padEnd(11)} ${orders.length} {w_d_orders}, ${data.queries - before} {w_d_queries}, ${ms} ms`);
}
await data.db.destroy();
''',
}


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.note(t["w_s_migrate"])
    s.run("npm run migrate --silent")
    s.save(folder / "migrate.sh")
    s.note(t["w_s_table"])
    s.run(r"psql shop -c '\d products'")
    s.note(t["w_s_history"])
    s.run("psql shop -c 'SELECT name, timestamp FROM kysely_migration ORDER BY name'")
    s.save(folder / "table.sh")
    s.note(t["w_s_down"])
    s.run("npm run migrate --silent -- down")
    s.run("npm run migrate --silent")
    s.save(folder / "down.sh")
    s.note(t["w_s_codegen"])
    s.run("npm run db:types --silent 2>&1 | grep -v '^$'")
    s.save(folder / "codegen.sh")
    s.note(t["w_s_typo"])
    s.run("npx tsc", check=False)
    s.save(folder / "typo.sh")
    s.run("node --env-file=.env src/seed.ts")
    s.lines.clear()
    s.note(t["w_s_query"])
    s.run("node --env-file=.env demos/order.ts")
    s.save(folder / "order.sh")
    s.note(t["w_s_n1"])
    s.run("node --env-file=.env demos/n-plus-one.ts")
    s.save(folder / "n-plus-one.sh")
    # Exercise 2's answer: the status column typed as the four values its CHECK allows.
    (folder / "answers").mkdir(exist_ok=True)
    s.run("npx kysely-codegen --env-file=.env --type-mapping '{\"int8\":\"number\"}' "
          "--overrides '{\"columns\":{\"orders.status\":\"\\\"pending\\\" | \\\"paid\\\" | "
          "\\\"shipped\\\" | \\\"cancelled\\\"\"}}' --out-file answers/db-types.ts > /dev/null 2>&1; "
          "grep -A5 'interface Orders' answers/db-types.ts")
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
    subprocess.run(["npx", "prettier", "--print-width", "84", "--write", "src", "demos", "migrations"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
