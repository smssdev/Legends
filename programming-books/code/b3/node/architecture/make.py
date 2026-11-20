"""Writes the examples of Book 3 (Node edition), the chapter "Architecture: Keeping Code Easy to Change".
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start)

The order feature rebuilt in layers inside one module: pure domain rules (order.ts), a use case that
orchestrates them through ports (place-order.ts, ports.ts), adapters for PostgreSQL and HTTP, and a
composition root that wires them. The use case is tested in milliseconds with in-memory fakes, the route
runs against PostgreSQL, and an architecture test fails when a layer imports what it must not.
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
from rec import CLEAN, Server, Session, fill  # noqa: E402

URL = "postgres://bit:secret@localhost:5432/shop"

T = {
    "en": dict(
        w_kit="Robot kit", w_wheels="Spare wheels",
        w_c_domain="the domain: the shop's rules, in plain TypeScript; no database, no HTTP, no framework",
        w_c_limit="a rule of the business, not of the database or the API",
        w_c_errors="errors that speak the business's language; each adapter decides what they become",
        w_c_ports="ports: what the use case needs from the outside world, described by the use case",
        w_c_case="the use case: one thing the shop does, start to finish, through its ports",
        w_c_after="the email after the order is saved, never inside its transaction",
        w_c_adapter="an adapter: the OrderStore port, implemented with Kysely and PostgreSQL",
        w_c_http="the HTTP adapter: translate the request in, the result or the error out",
        w_c_root="the composition root: the only place that knows every concrete piece",
        w_c_fakes="fakes: the ports, implemented in memory for tests",
        w_c_rules="which folders each layer may import from",
        w_m_limit="At most 10 of one product per order", w_m_stock="Not enough stock",
        w_m_unknown="Unknown product",
        w_t_places="places an order, saves it and sends one email",
        w_t_limit="refuses more than 10 of one product, before touching the store",
        w_t_stock="sends no email when the store reports too little stock",
        w_t_layers="each layer imports only what it may",
        w_s_tree="The order module", w_s_test="The tests: a use case without a database, and the rules",
        w_s_place="An order", w_s_limit="Eleven of one product", w_s_stock="More than the stock",
        w_s_break="Someone imports the database into the domain",
    ),
    "ar": dict(
        w_kit="عدة الروبوت", w_wheels="عجلات احتياطية",
        w_c_domain="المجال: قواعد المتجر، بـ TypeScript عادية؛ بلا قاعدة بيانات، ولا HTTP، ولا إطار",
        w_c_limit="قاعدة من قواعد العمل، لا من قواعد قاعدة البيانات ولا API",
        w_c_errors="أخطاء تتكلم لغة العمل؛ وكل محوّل يقرر ماذا تصير",
        w_c_ports="المنافذ: ما تحتاجه حالة الاستخدام من العالم الخارجي، كما تصفه هي",
        w_c_case="حالة الاستخدام: شيء واحد يفعله المتجر، من البداية إلى النهاية، عبر منافذها",
        w_c_after="البريد بعد حفظ الطلب، لا داخل معاملته أبداً",
        w_c_adapter="محوّل: المنفذ OrderStore، مطبَّقاً بـ Kysely وPostgreSQL",
        w_c_http="محوّل HTTP: يترجم الطلب إلى الداخل، والنتيجة أو الخطأ إلى الخارج",
        w_c_root="جذر التركيب: المكان الوحيد الذي يعرف كل قطعة حقيقية",
        w_c_fakes="البدائل: المنافذ، مطبَّقة في الذاكرة للاختبارات",
        w_c_rules="من أي المجلدات يجوز لكل طبقة أن تستورد",
        w_m_limit="10 على الأكثر من المنتج الواحد في الطلب", w_m_stock="المخزون لا يكفي",
        w_m_unknown="منتج مجهول",
        w_t_places="places an order, saves it and sends one email",
        w_t_limit="refuses more than 10 of one product, before touching the store",
        w_t_stock="sends no email when the store reports too little stock",
        w_t_layers="each layer imports only what it may",
        w_s_tree="وحدة الطلبات", w_s_test="الاختبارات: حالة استخدام بلا قاعدة بيانات، والقواعد",
        w_s_place="طلب", w_s_limit="أحد عشر من منتج واحد", w_s_stock="أكثر من المخزون",
        w_s_break="أحدهم يستورد قاعدة البيانات في المجال",
    ),
}

FILES = {
    ".env": f"DATABASE_URL={URL}\n",
    "package.json": '''{
  "name": "bit-shop-architecture",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node --env-file=.env src/server.ts",
    "test": "node --test --test-reporter=spec",
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
    "schema.sql": '''CREATE TABLE products (id bigint PRIMARY KEY, name text NOT NULL, price integer NOT NULL,
  stock integer NOT NULL CHECK (stock >= 0));
CREATE TABLE orders (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, email text NOT NULL,
  total integer NOT NULL, placed_at timestamptz NOT NULL);
CREATE TABLE order_items (order_id bigint NOT NULL REFERENCES orders (id), product_id bigint NOT NULL,
  quantity integer NOT NULL, price integer NOT NULL);
INSERT INTO products VALUES (1, '{w_kit}', 45000, 5), (2, '{w_wheels}', 6000, 50);
''',
    "src/orders/order.ts": '''// {w_c_domain}
export type Line = { productId: number; quantity: number; price: number };
export type Order = { id: number; email: string; lines: Line[]; total: number; placedAt: Date };

// {w_c_errors}
export class OrderError extends Error {}
export class TooMany extends OrderError {}
export class OutOfStock extends OrderError {}
export class UnknownProduct extends OrderError {}

// {w_c_limit}
export const MAX_PER_PRODUCT = 10;

export function checkQuantities(items: { productId: number; quantity: number }[]) {
  for (const item of items) {
    if (item.quantity > MAX_PER_PRODUCT) throw new TooMany("{w_m_limit}");
  }
}

export const totalOf = (lines: Line[]) =>
  lines.reduce((sum, l) => sum + l.price * l.quantity, 0);
''',
    "src/orders/ports.ts": '''import type { Line, Order } from "./order.ts";

// {w_c_ports}
export type OrderStore = {
  /** Takes the stock and saves the order, all or nothing; prices come from the store. */
  place(email: string, items: Omit<Line, "price">[], placedAt: Date): Promise<Order>;
};
export type Mailer = { send(to: string, subject: string): Promise<void> };
export type Clock = { now(): Date };
''',
    "src/orders/place-order.ts": '''import { checkQuantities } from "./order.ts";
import type { Clock, Mailer, OrderStore } from "./ports.ts";

type Deps = { store: OrderStore; mailer: Mailer; clock: Clock };
type Input = { email: string; items: { productId: number; quantity: number }[] };

// {w_c_case}
export function makePlaceOrder({ store, mailer, clock }: Deps) {
  return async function placeOrder({ email, items }: Input) {
    checkQuantities(items);
    const order = await store.place(email, items, clock.now());
    // {w_c_after}
    await mailer.send(email, `Order ${order.id}: ${order.total / 100} EGP`);
    return order;
  };
}
''',
    "src/orders/kysely-store.ts": '''import type { Kysely } from "kysely";
import type { DB } from "../db.ts";
import { OutOfStock, totalOf, UnknownProduct, type Line } from "./order.ts";
import type { OrderStore } from "./ports.ts";

// {w_c_adapter}
export function kyselyOrderStore(db: Kysely<DB>): OrderStore {
  return {
    place: (email, items, placedAt) =>
      db.transaction().execute(async (trx) => {
        const lines: Line[] = [];
        for (const { productId, quantity } of items) {
          const row = await trx
            .updateTable("products")
            .set((eb) => ({ stock: eb("stock", "-", quantity) }))
            .where("id", "=", productId)
            .where("stock", ">=", quantity)
            .returning("price")
            .executeTakeFirst();
          if (!row) {
            const exists = await trx
              .selectFrom("products")
              .select("id")
              .where("id", "=", productId)
              .executeTakeFirst();
            throw exists ? new OutOfStock("{w_m_stock}") : new UnknownProduct("{w_m_unknown}");
          }
          lines.push({ productId, quantity, price: row.price });
        }
        const total = totalOf(lines);
        const { id } = await trx
          .insertInto("orders")
          .values({ email, total, placed_at: placedAt })
          .returning("id")
          .executeTakeFirstOrThrow();
        await trx
          .insertInto("order_items")
          .values(lines.map((l) => ({ order_id: id, product_id: l.productId, quantity: l.quantity, price: l.price })))
          .execute();
        return { id, email, lines, total, placedAt };
      }),
  };
}
''',
    "src/orders/routes.ts": '''import type { FastifyPluginAsync } from "fastify";
import { OrderError, OutOfStock, TooMany, UnknownProduct } from "./order.ts";

type PlaceOrder = (input: {
  email: string;
  items: { productId: number; quantity: number }[];
}) => Promise<{ id: number; total: number }>;

// {w_c_http}
export const orderRoutes =
  (placeOrder: PlaceOrder): FastifyPluginAsync =>
  async (app) => {
    app.post<{ Body: { email: string; items: { productId: number; quantity: number }[] } }>(
      "/orders",
      async (request, reply) => {
        try {
          const order = await placeOrder(request.body);
          return reply.code(201).send({ id: order.id, total: order.total });
        } catch (error) {
          if (!(error instanceof OrderError)) throw error;
          const status =
            error instanceof TooMany ? 422 : error instanceof OutOfStock ? 409 : error instanceof UnknownProduct ? 422 : 400;
          return reply.code(status).send({ title: error.message, status });
        }
      },
    );
  };
''',
    "src/db.ts": '''import { type Generated, Kysely, PostgresDialect } from "kysely";
import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

export type DB = {
  products: { id: number; name: string; price: number; stock: number };
  orders: { id: Generated<number>; email: string; total: number; placed_at: Date };
  order_items: { order_id: number; product_id: number; quantity: number; price: number };
};

export const connect = () =>
  new Kysely<DB>({
    dialect: new PostgresDialect({
      pool: new pg.Pool({ connectionString: process.env.DATABASE_URL }),
    }),
  });
''',
    "src/server.ts": '''import Fastify from "fastify";
import { connect } from "./db.ts";
import { kyselyOrderStore } from "./orders/kysely-store.ts";
import { makePlaceOrder } from "./orders/place-order.ts";
import { orderRoutes } from "./orders/routes.ts";

// {w_c_root}
const db = connect();
const placeOrder = makePlaceOrder({
  store: kyselyOrderStore(db),
  mailer: { send: async (to, subject) => console.log(`mail to ${to}: ${subject}`) },
  clock: { now: () => new Date() },
});

const app = Fastify();
await app.register(orderRoutes(placeOrder));
app.get("/ready", async () => ({ ready: true }));
await app.listen({ port: 3000 });
''',
    "test/place-order.test.ts": '''import assert from "node:assert/strict";
import { test } from "node:test";
import { OutOfStock, TooMany } from "../src/orders/order.ts";
import { makePlaceOrder } from "../src/orders/place-order.ts";
import type { OrderStore } from "../src/orders/ports.ts";

// {w_c_fakes}
function fakes(store: OrderStore["place"]) {
  const sent: string[] = [];
  const placeOrder = makePlaceOrder({
    store: { place: store },
    mailer: { send: async (to) => void sent.push(to) },
    clock: { now: () => new Date("2026-11-20T10:00:00Z") },
  });
  return { placeOrder, sent };
}

test("{w_t_places}", async () => {
  const saved: unknown[] = [];
  const { placeOrder, sent } = fakes(async (email, items, placedAt) => {
    const lines = items.map((i) => ({ ...i, price: 6000 }));
    saved.push({ email, placedAt });
    return { id: 7, email, lines, total: 12000, placedAt };
  });
  const order = await placeOrder({ email: "sara@example.com", items: [{ productId: 2, quantity: 2 }] });
  assert.equal(order.total, 12000);
  assert.deepEqual(saved, [{ email: "sara@example.com", placedAt: new Date("2026-11-20T10:00:00Z") }]);
  assert.deepEqual(sent, ["sara@example.com"]);
});

test("{w_t_limit}", async () => {
  const { placeOrder } = fakes(async () => assert.fail("the store must not be called"));
  await assert.rejects(placeOrder({ email: "a@b.c", items: [{ productId: 1, quantity: 11 }] }), TooMany);
});

test("{w_t_stock}", async () => {
  const { placeOrder, sent } = fakes(async () => {
    throw new OutOfStock("no");
  });
  await assert.rejects(placeOrder({ email: "a@b.c", items: [{ productId: 1, quantity: 9 }] }), OutOfStock);
  assert.deepEqual(sent, []);
});
''',
    "test/architecture.test.ts": '''import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { test } from "node:test";

// {w_c_rules}
const rules: Record<string, RegExp> = {
  "order.ts": /^$/,
  "ports.ts": /^\\.\\/order\\.ts$/,
  "place-order.ts": /^\\.\\/(order|ports)\\.ts$/,
};

test("{w_t_layers}", () => {
  const folder = "src/orders";
  for (const file of readdirSync(folder)) {
    const allowed = rules[file];
    if (!allowed) continue;
    const source = readFileSync(`${folder}/${file}`, "utf8");
    for (const [, from] of source.matchAll(/from "([^"]+)"/g)) {
      assert.match(from!, allowed, `${file} must not import ${from}`);
    }
  }
});
''',
}


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("psql shop -q -f schema.sql")
    s.run("npx tsc")
    s.lines.clear()
    s.note(t["w_s_tree"])
    s.run("ls src src/orders test")
    s.save(folder / "tree.sh")
    s.note(t["w_s_test"])
    s.run("npm test --silent 2>&1 | grep -v '^$\\|duration_ms' | sed -E 's/\\(([0-9.]+)ms\\)/(…ms)/'",
          shown="npm test")
    s.save(folder / "test.sh")

    post = ("curl -s localhost:3000/orders -H 'content-type: application/json' "
            "-d '{{\"email\":\"sara@example.com\",\"items\":[{items}]}}' | jq -c")
    with Server("node --env-file=.env src/server.ts", folder, "http://localhost:3000/ready") as server:
        s.note(t["w_s_place"])
        s.run(post.format(items='{"productId":1,"quantity":2},{"productId":2,"quantity":4}'))
        s.note(t["w_s_limit"])
        s.run(post.format(items='{"productId":2,"quantity":11}'))
        s.note(t["w_s_stock"])
        s.run(post.format(items='{"productId":1,"quantity":4}'))
        s.run("psql shop -c 'SELECT id, stock FROM products ORDER BY id'")
        s.add("$ npm start")
        s.add("\n".join(line for line in server.log().split("\n") if line.startswith("mail")))
        s.save(folder / "http.sh")

    domain = folder / "src/orders/order.ts"
    original = domain.read_text()
    domain.write_text('import { connect } from "../db.ts";\n' + original)
    s.note(t["w_s_break"])
    s.run("npm test --silent -- test/architecture.test.ts 2>&1 | grep -E '✖ each|must not import' "
          "| sed -E 's/ \\([0-9.]+ms\\)//; s/^ +//' | awk '!seen[$0]++' | head -2",
          shown="npm test -- test/architecture.test.ts", check=False)
    s.save(folder / "break.sh")
    domain.write_text(original)


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
