"""Writes the examples of Book 3 (Node.js edition), chapter 3 "Designing REST APIs".
Run: python3 make.py   (after `npm ci` in code/b3)

The shop's API, version 1, on Fastify with zod schemas: cursor pagination, filtering and sorting, errors as
Problem Details (RFC 9457), idempotency keys, optimistic concurrency with ETag and If-Match, rate limits,
and an OpenAPI document generated from the same schemas. The server is started for real and curl talks
to it; what the terminal showed is saved as the transcripts the chapter prints (*.sh).
"""
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent.parent
sys.path.insert(0, str(B3))
from rec import Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_q="se",
        w_names='"Robot kit", "Spare wheels", "Battery pack", "USB cable", "Servo motor", "Sensor set", '
                '"Remote control", "Solar panel", "Gear box", "LED strip", "Speaker", "Camera module"',
        w_p_invalid="Invalid request", w_p_body="Invalid body", w_p_not_found="Not found",
        w_p_no_product="There is no product {id}.", w_p_no_order="There is no order {id}.",
        w_p_precondition="Precondition required", w_p_need_if_match="Send If-Match with the ETag you last read.",
        w_p_stale="The product has changed", w_p_stale_detail="Someone changed it after you read it. Read it again.",
        w_p_reused="Idempotency key reused", w_p_reused_detail="This key was used with a different body.",
        w_p_in_progress="Request in progress", w_p_in_progress_detail="A request with this key is still running.",
        w_p_stock="Not enough stock", w_p_stock_detail="Only {stock} left of product {id}.",
        w_p_unknown="Unknown product", w_p_state="Order cannot be cancelled",
        w_p_state_detail="Order {id} is already {status}.", w_p_limit="Too many requests",
        w_p_limit_detail="Try again in {seconds} seconds.", w_p_server="Server error",
        w_p_empty="Send at least one field to change.",
        w_title="Bit's shop API", w_desc="Products and orders. Money is in piastres; times are UTC.",
        w_c_slug="every problem type has its own page of documentation at this address",
        w_c_keyset="the cursor is the last row's sort value and id; start after it",
        w_c_opaque="opaque to clients: base64url, so nobody builds cursors by hand",
        w_c_server_price="the price comes from the server, never from the client",
        w_c_remember="remembered for 24 hours in a real system, in the database or Redis",
        w_c_mark="mark the key as in progress before doing the work",
        w_c_400="a bad query, path or header: the request itself is malformed",
        w_c_422="a well-formed body with wrong values",
        w_c_hide="the details stay in the log",
        w_t_pages="walks every page without repeats or gaps", w_t_sorted="sorts by price, highest first",
        w_t_replay="replays an order instead of creating it twice", w_t_stale="refuses a stale update with 412",
        w_t_invalid="answers 422 with every invalid field",
        w_d_offset="offset", w_d_cursor="cursor", w_d_page="page", w_d_new="a new product arrives: id",
        w_s_routes="The API's routes, read from its own OpenAPI document",
        w_s_first="The first page", w_s_next="The next page: send back the cursor you were given",
        w_s_filter="Filter and sort: the cursor remembers both",
        w_s_bad="Values outside the rules are refused before any code runs",
        w_s_read="Read a product: the ETag is its version",
        w_s_no_match="Change it without If-Match", w_s_ok="Change it with the ETag just read",
        w_s_stale="Someone else, still holding the old ETag, tries the same",
        w_s_order="Create an order, with an idempotency key",
        w_s_again="The network failed, so the client sends exactly the same request again",
        w_s_other="The same key with a different body is a client bug",
        w_s_stock_once="The stock went down once, not twice",
        w_s_too_many="More than the stock", w_s_cancel="Cancel, then cancel again",
        w_s_limit="A server limited to 3 requests a minute (RATE_LIMIT=3)",
        w_s_drift="The same pages, with offset and with a cursor, while a product is added",
        w_s_test="The tests talk to the app without a network, with inject",
    ),
    "ar": dict(
        w_q="حز",
        w_names='"عدة الروبوت", "عجلات احتياطية", "حزمة بطارية", "كابل USB", "محرك سيرفو", "طقم حساسات", '
                '"جهاز تحكم", "لوح شمسي", "صندوق تروس", "شريط LED", "سماعة", "وحدة كاميرا"',
        w_p_invalid="طلب غير صالح", w_p_body="محتوى غير صالح", w_p_not_found="غير موجود",
        w_p_no_product="لا يوجد منتج رقمه {id}.", w_p_no_order="لا يوجد طلب رقمه {id}.",
        w_p_precondition="شرط مسبق مطلوب", w_p_need_if_match="أرسل If-Match مع آخر ETag قرأته.",
        w_p_stale="تغيّر المنتج", w_p_stale_detail="غيّره أحد بعد أن قرأته. اقرأه من جديد.",
        w_p_reused="مفتاح عدم التكرار مستخدم", w_p_reused_detail="استُخدم هذا المفتاح مع محتوى مختلف.",
        w_p_in_progress="الطلب قيد التنفيذ", w_p_in_progress_detail="ما زال طلب بهذا المفتاح يعمل.",
        w_p_stock="المخزون لا يكفي", w_p_stock_detail="بقي {stock} فقط من المنتج {id}.",
        w_p_unknown="منتج مجهول", w_p_state="لا يمكن إلغاء الطلب",
        w_p_state_detail="الطلب {id} حالته {status} من قبل.", w_p_limit="طلبات كثيرة جداً",
        w_p_limit_detail="حاول مرة أخرى بعد {seconds} ثانية.", w_p_server="خطأ في الخادم",
        w_p_empty="أرسل حقلاً واحداً على الأقل لتغييره.",
        w_title="واجهة متجر Bit", w_desc="المنتجات والطلبات. المال بالقروش، والأوقات بتوقيت UTC.",
        w_c_slug="لكل نوع مشكلة صفحة توثيق خاصة به على هذا العنوان",
        w_c_keyset="المؤشر قيمة الترتيب ورقم آخر صف: الصفحة تبدأ بعده",
        w_c_opaque="غامض للعملاء: base64url، فلا يصنع أحد المؤشرات بيده",
        w_c_server_price="السعر يأتي من الخادم، لا من العميل أبداً",
        w_c_remember="يُحفظ 24 ساعة في نظام حقيقي، في قاعدة البيانات أو Redis",
        w_c_mark="علّم المفتاح بأنه قيد التنفيذ قبل أداء العمل",
        w_c_400="استعلام أو مسار أو ترويسة خاطئة: الطلب نفسه مشوّه",
        w_c_422="محتوى سليم الشكل بقيم خاطئة",
        w_c_hide="التفاصيل تبقى في السجل",
        w_t_pages="يمر على كل الصفحات بلا تكرار ولا فجوات", w_t_sorted="يرتب بالسعر، الأعلى أولاً",
        w_t_replay="يعيد جواب الطلب بدل أن ينشئه مرتين", w_t_stale="يرفض التحديث القديم بـ 412",
        w_t_invalid="يرد بـ 422 مع كل حقل غير صالح",
        w_d_offset="الإزاحة", w_d_cursor="المؤشر", w_d_page="الصفحة", w_d_new="يصل منتج جديد: رقمه",
        w_s_routes="مسارات الواجهة، مقروءة من وثيقة OpenAPI الخاصة بها",
        w_s_first="الصفحة الأولى", w_s_next="الصفحة التالية: أعد المؤشر الذي أُعطيته",
        w_s_filter="التصفية والترتيب: المؤشر يتذكر الاثنين",
        w_s_bad="القيم الخارجة عن القواعد تُرفض قبل أن يعمل أي كود",
        w_s_read="اقرأ منتجاً: الوسم ETag هو إصداره",
        w_s_no_match="غيّره دون If-Match", w_s_ok="غيّره مع الوسم الذي قرأته للتو",
        w_s_stale="شخص آخر ما زال يحمل الوسم القديم يحاول الشيء نفسه",
        w_s_order="أنشئ طلباً، مع مفتاح عدم التكرار",
        w_s_again="فشلت الشبكة، فأرسل العميل الطلب نفسه بالضبط مرة أخرى",
        w_s_other="المفتاح نفسه مع محتوى مختلف خطأ في العميل",
        w_s_stock_once="نقص المخزون مرة واحدة، لا مرتين",
        w_s_too_many="أكثر من المخزون", w_s_cancel="ألغِ، ثم ألغِ مرة أخرى",
        w_s_limit="خادم محدود بثلاثة طلبات في الدقيقة (RATE_LIMIT=3)",
        w_s_drift="الصفحات نفسها، بالإزاحة وبالمؤشر، بينما يُضاف منتج",
        w_s_test="تتحدث الاختبارات إلى التطبيق بلا شبكة، بـ inject",
    ),
}

# The comments written in English in FILES, for the Arabic edition.
COMMENTS_AR = {
    "An action, not create, read, update or delete: a sub-resource, with POST.":
        "فعل ليس إنشاءً ولا قراءة ولا تحديثاً ولا حذفاً: مورد فرعي بـ POST.",
    "Errors as Problem Details (RFC 9457): one format for every error the API returns.":
        "الأخطاء بصيغة Problem Details (RFC 9457): صيغة واحدة لكل خطأ ترده الواجهة.",
    "Every problem the API can return, so routes never invent their own.":
        "كل مشكلة تستطيع الواجهة ردها، فلا يخترع مسار مشكلة خاصة به.",
    "Every text a person reads, in one place: easy to review, easy to translate.":
        "كل نص يقرؤه إنسان في مكان واحد: سهل المراجعة، سهل الترجمة.",
    'Newest first, like "new arrivals". Page 1 is read, then a product is added.':
        "الأحدث أولاً، مثل «وصل حديثاً». تُقرأ الصفحة 1، ثم يُضاف منتج.",
    "Rows are ordered by the sort field, then by id, so the order is always complete.":
        "تُرتب الصفوف بحقل الترتيب ثم بالرقم، فيكون الترتيب كاملاً دائماً.",
    "The shop's data, in memory for now: Part 2 moves it to PostgreSQL.":
        "بيانات المتجر في الذاكرة الآن، وينقلها الجزء الثاني إلى PostgreSQL.",
    "a failed attempt may be tried again with the same key": "المحاولة الفاشلة يجوز تكرارها بالمفتاح نفسه",
    "piastres": "بالقروش",
    "goes up with every change: the ETag": "يزيد مع كل تغيير: إنه ETag",
    "{placeholders} are filled in by say().": "تملأ say() الأماكن بين الأقواس {}.",
}

FILES = {
    "package.json": '''{
  "name": "bit-shop-api",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node src/server.ts",
    "check": "tsc",
    "test": "node --test --test-reporter=spec"
  },
  "dependencies": {
    "@fastify/rate-limit": "^11.2.2",
    "@fastify/swagger": "^9.9.5",
    "fastify": "^5.12.8",
    "fastify-type-provider-zod": "^7.0.0",
    "zod": "^4.6.7"
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
    "src/store.ts": '''// The shop's data, in memory for now: Part 2 moves it to PostgreSQL.
export type Product = {
  id: number;
  name: string;
  price: number; // piastres
  stock: number;
  version: number; // goes up with every change: the ETag
  created_at: string;
};

export type Order = {
  id: number;
  status: "pending" | "cancelled";
  items: { product_id: number; quantity: number; price: number }[];
  total: number;
  created_at: string;
};

const names = [
{w_names_list}
];
const prices = [
  45000, 6000, 12500, 2500, 9000, 15000, 8000, 30000, 11000, 4000, 7500, 21000,
];

export function createStore() {
  const start = Date.parse("2026-11-01T09:00:00Z");
  const products: Product[] = names.map((name, i) => ({
    id: i + 1,
    name,
    price: prices[i] ?? 1000,
    stock: 10,
    version: 1,
    created_at: new Date(start + i * 3_600_000).toISOString(),
  }));
  return { products, orders: [] as Order[], nextOrderId: 1 };
}

export type Store = ReturnType<typeof createStore>;
''',
    "src/messages.ts": '''// Every text a person reads, in one place: easy to review, easy to translate.
// {placeholders} are filled in by say().
export const messages = {
  invalidRequest: "{w_p_invalid}",
  invalidBody: "{w_p_body}",
  notFound: "{w_p_not_found}",
  noProduct: "{w_p_no_product}",
  noOrder: "{w_p_no_order}",
  preconditionRequired: "{w_p_precondition}",
  needIfMatch: "{w_p_need_if_match}",
  stale: "{w_p_stale}",
  staleDetail: "{w_p_stale_detail}",
  keyReused: "{w_p_reused}",
  keyReusedDetail: "{w_p_reused_detail}",
  inProgress: "{w_p_in_progress}",
  inProgressDetail: "{w_p_in_progress_detail}",
  outOfStock: "{w_p_stock}",
  outOfStockDetail: "{w_p_stock_detail}",
  unknownProduct: "{w_p_unknown}",
  cannotCancel: "{w_p_state}",
  cannotCancelDetail: "{w_p_state_detail}",
  tooManyRequests: "{w_p_limit}",
  tooManyRequestsDetail: "{w_p_limit_detail}",
  serverError: "{w_p_server}",
  emptyPatch: "{w_p_empty}",
};

export function say(text: string, values: Record<string, string | number> = {}): string {
  return text.replace(/\\{(\\w+)\\}/g, (_, key: string) => String(values[key]));
}
''',
    "src/problem.ts": '''import { messages as m, say } from "./messages.ts";

// Errors as Problem Details (RFC 9457): one format for every error the API returns.
export class Problem extends Error {
  status: number;
  slug: string;
  title: string;
  detail?: string;
  extra: Record<string, unknown>;

  constructor(status: number, slug: string, title: string, detail?: string, extra = {}) {
    super(title);
    this.status = status;
    this.slug = slug;
    this.title = title;
    this.detail = detail;
    this.extra = extra;
  }

  body(instance: string) {
    return {
      // {w_c_slug}
      type: `https://bit-shop.example/problems/${this.slug}`,
      title: this.title,
      status: this.status,
      ...(this.detail && { detail: this.detail }),
      instance,
      ...this.extra,
    };
  }
}

type Errors = { field: string; message: string }[];

// Every problem the API can return, so routes never invent their own.
export const problems = {
  invalidRequest: (errors: Errors) =>
    new Problem(400, "invalid-request", m.invalidRequest, undefined, { errors }),
  invalidBody: (errors: Errors) =>
    new Problem(422, "invalid-body", m.invalidBody, undefined, { errors }),
  noProduct: (id: number) =>
    new Problem(404, "not-found", m.notFound, say(m.noProduct, { id })),
  noOrder: (id: number) =>
    new Problem(404, "not-found", m.notFound, say(m.noOrder, { id })),
  needIfMatch: () =>
    new Problem(428, "precondition-required", m.preconditionRequired, m.needIfMatch),
  stale: () => new Problem(412, "stale", m.stale, m.staleDetail),
  keyReused: () =>
    new Problem(422, "idempotency-key-reused", m.keyReused, m.keyReusedDetail),
  inProgress: () => new Problem(409, "in-progress", m.inProgress, m.inProgressDetail),
  outOfStock: (id: number, stock: number) =>
    new Problem(409, "out-of-stock", m.outOfStock, say(m.outOfStockDetail, { id, stock })),
  unknownProduct: (id: number) =>
    new Problem(422, "unknown-product", m.unknownProduct, say(m.noProduct, { id })),
  cannotCancel: (id: number, status: string) =>
    new Problem(409, "invalid-state", m.cannotCancel,
      say(m.cannotCancelDetail, { id, status })),
  tooManyRequests: (seconds: number) =>
    new Problem(429, "too-many-requests", m.tooManyRequests,
      say(m.tooManyRequestsDetail, { seconds })),
  server: () => new Problem(500, "server-error", m.serverError),
};
''',
    "src/schemas.ts": '''import { z } from "zod";

export const Money = z.object({
  amount: z.number().int().describe("piastres"),
  currency: z.literal("EGP"),
});

export const ProductOut = z.object({
  id: z.number().int(),
  name: z.string(),
  price: Money,
  stock: z.number().int(),
  created_at: z.iso.datetime(),
});

export const OrderItemOut = z.object({
  product_id: z.number().int(),
  quantity: z.number().int(),
  price: Money,
});

export const OrderOut = z.object({
  id: z.number().int(),
  status: z.enum(["pending", "cancelled"]),
  items: z.array(OrderItemOut),
  total: Money,
  created_at: z.iso.datetime(),
});

export const IdParams = z.object({ id: z.coerce.number().int().positive() });

export const egp = (amount: number) => ({ amount, currency: "EGP" as const });
''',
    "src/routes/products.ts": '''import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import { messages } from "../messages.ts";
import { problems } from "../problem.ts";
import { egp, IdParams, ProductOut } from "../schemas.ts";
import type { Product, Store } from "../store.ts";

const SORTS = { id: "id", price: "price", "-price": "price", name: "name" } as const;
type Sort = keyof typeof SORTS;
type Position = [value: string | number, id: number];

const ListQuery = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(5),
  cursor: z.string().optional(),
  sort: z.enum(["id", "price", "-price", "name"]).default("id"),
  min_price: z.coerce.number().int().min(0).optional(),
  max_price: z.coerce.number().int().min(0).optional(),
});

const ProductPatch = z
  .strictObject({
    name: z.string().trim().min(1).max(80).optional(),
    price: z.number().int().positive().optional(),
    stock: z.number().int().min(0).optional(),
  })
  .refine((body) => Object.keys(body).length > 0, messages.emptyPatch);

const show = (p: Product) => ({ ...p, price: egp(p.price) });

// Rows are ordered by the sort field, then by id, so the order is always complete.
function compare(row: Product, [value, id]: Position, sort: Sort): number {
  const own = row[SORTS[sort]];
  const diff = own < value ? -1 : own > value ? 1 : row.id - id;
  return sort === "-price" ? -diff : diff;
}

// {w_c_opaque}
const encode = (position: Position) =>
  Buffer.from(JSON.stringify(position)).toString("base64url");

function decode(cursor: string): Position {
  try {
    const position = JSON.parse(Buffer.from(cursor, "base64url").toString());
    if (Array.isArray(position) && position.length === 2) return position as Position;
  } catch {}
  const error = { field: "querystring.cursor", message: "invalid cursor" };
  throw problems.invalidRequest([error]);
}

export const productRoutes =
  (store: Store): FastifyPluginAsyncZod =>
  async (app) => {
    const find = (id: number) => {
      const product = store.products.find((p) => p.id === id);
      if (!product) throw problems.noProduct(id);
      return product;
    };

    app.get(
      "/products",
      {
        schema: {
          querystring: ListQuery,
          response: {
            200: z.object({
              data: z.array(ProductOut),
              next_cursor: z.string().nullable(),
            }),
          },
        },
      },
      async (request) => {
        const { limit, cursor, sort, min_price, max_price } = request.query;
        const field = SORTS[sort];
        let rows = store.products
          .filter((p) => min_price === undefined || p.price >= min_price)
          .filter((p) => max_price === undefined || p.price <= max_price)
          .sort((a, b) => compare(a, [b[field], b.id], sort));
        if (cursor) {
          // {w_c_keyset}
          const after = decode(cursor);
          rows = rows.filter((p) => compare(p, after, sort) > 0);
        }
        const page = rows.slice(0, limit);
        const last = page.at(-1);
        const next = rows.length > limit && last ? encode([last[field], last.id]) : null;
        return { data: page.map(show), next_cursor: next };
      },
    );

    app.get(
      "/products/:id",
      { schema: { params: IdParams, response: { 200: ProductOut, 304: z.null() } } },
      async (request, reply) => {
        const product = find(request.params.id);
        const etag = `"${product.version}"`;
        reply.header("ETag", etag);
        if (request.headers["if-none-match"] === etag) return reply.code(304).send(null);
        return show(product);
      },
    );

    app.patch(
      "/products/:id",
      { schema: { params: IdParams, body: ProductPatch, response: { 200: ProductOut } } },
      async (request, reply) => {
        const product = find(request.params.id);
        const ifMatch = request.headers["if-match"];
        if (!ifMatch) throw problems.needIfMatch();
        if (ifMatch !== `"${product.version}"`) throw problems.stale();
        Object.assign(product, request.body, { version: product.version + 1 });
        reply.header("ETag", `"${product.version}"`);
        return show(product);
      },
    );
  };
''',
    "src/routes/orders.ts": '''import { createHash } from "node:crypto";
import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import { problems } from "../problem.ts";
import { egp, IdParams, OrderOut } from "../schemas.ts";
import type { Order, Store } from "../store.ts";

const NewOrder = z.strictObject({
  items: z
    .array(
      z.strictObject({
        product_id: z.number().int(),
        quantity: z.number().int().min(1).max(99),
      }),
    )
    .min(1)
    .max(20),
});

const show = (o: Order): z.infer<typeof OrderOut> => ({
  ...o,
  items: o.items.map((item) => ({ ...item, price: egp(item.price) })),
  total: egp(o.total),
});

type Saved = { fingerprint: string; order?: z.infer<typeof OrderOut> };

export const orderRoutes =
  (store: Store): FastifyPluginAsyncZod =>
  async (app) => {
    // {w_c_remember}
    const keys = new Map<string, Saved>();

    app.post(
      "/orders",
      {
        schema: {
          headers: z.object({ "idempotency-key": z.string().min(8).max(100) }),
          body: NewOrder,
          response: { 201: OrderOut },
        },
      },
      async (request, reply) => {
        const key = request.headers["idempotency-key"];
        const body = JSON.stringify(request.body);
        const fingerprint = createHash("sha256").update(body).digest("hex");
        const saved = keys.get(key);
        if (saved) {
          if (saved.fingerprint !== fingerprint) throw problems.keyReused();
          if (!saved.order) throw problems.inProgress();
          reply.header("Idempotent-Replayed", "true");
          reply.header("Location", `/v1/orders/${saved.order.id}`);
          return reply.code(201).send(saved.order);
        }
        // {w_c_mark}
        keys.set(key, { fingerprint });

        try {
          const items = request.body.items.map(({ product_id, quantity }) => {
            const product = store.products.find((p) => p.id === product_id);
            if (!product) throw problems.unknownProduct(product_id);
            if (product.stock < quantity) {
              throw problems.outOfStock(product.id, product.stock);
            }
            return { product, quantity };
          });
          for (const { product, quantity } of items) {
            product.stock -= quantity;
            product.version += 1;
          }
          const order: Order = {
            id: store.nextOrderId++,
            status: "pending",
            // {w_c_server_price}
            items: items.map(({ product, quantity }) => ({
              product_id: product.id,
              quantity,
              price: product.price,
            })),
            total: items.reduce(
              (sum, { product, quantity }) => sum + product.price * quantity,
              0,
            ),
            created_at: new Date().toISOString(),
          };
          store.orders.push(order);
          keys.set(key, { fingerprint, order: show(order) });
          reply.header("Location", `/v1/orders/${order.id}`);
          return reply.code(201).send(show(order));
        } catch (error) {
          keys.delete(key); // a failed attempt may be tried again with the same key
          throw error;
        }
      },
    );

    const find = (id: number) => {
      const order = store.orders.find((o) => o.id === id);
      if (!order) throw problems.noOrder(id);
      return order;
    };

    app.get(
      "/orders/:id",
      { schema: { params: IdParams, response: { 200: OrderOut } } },
      async (request) => show(find(request.params.id)),
    );

    // An action, not create, read, update or delete: a sub-resource, with POST.
    app.post(
      "/orders/:id/cancel",
      { schema: { params: IdParams, response: { 200: OrderOut } } },
      async (request) => {
        const order = find(request.params.id);
        if (order.status !== "pending") throw problems.cannotCancel(order.id, order.status);
        order.status = "cancelled";
        for (const item of order.items) {
          const product = store.products.find((p) => p.id === item.product_id);
          if (product) product.stock += item.quantity;
        }
        return show(order);
      },
    );
  };
''',
    "src/app.ts": '''import Fastify, { type FastifyError } from "fastify";
import rateLimit from "@fastify/rate-limit";
import swagger from "@fastify/swagger";
import {
  hasZodFastifySchemaValidationErrors,
  jsonSchemaTransform,
  serializerCompiler,
  validatorCompiler,
} from "fastify-type-provider-zod";
import { Problem, problems } from "./problem.ts";
import { orderRoutes } from "./routes/orders.ts";
import { productRoutes } from "./routes/products.ts";
import { createStore } from "./store.ts";

export async function buildApp(options: { rateLimit?: number } = {}) {
  const app = Fastify();
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  await app.register(swagger, {
    openapi: {
      info: {
        title: "{w_title}",
        description: "{w_desc}",
        version: "1.0.0",
      },
    },
    transform: jsonSchemaTransform,
  });
  await app.register(rateLimit, { max: options.rateLimit ?? 100, timeWindow: "1 minute" });

  app.setErrorHandler((error: FastifyError, request, reply) => {
    let problem: Problem;
    if (error instanceof Problem) {
      problem = error;
    } else if (hasZodFastifySchemaValidationErrors(error)) {
      const where = error.validationContext ?? "body";
      const errors = error.validation.map((issue) => ({
        field: [where, ...String(issue.instancePath).split("/").filter(Boolean)].join("."),
        message: issue.message ?? "",
      }));
      // 422: {w_c_422}
      // 400: {w_c_400}
      problem =
        where === "body" ? problems.invalidBody(errors) : problems.invalidRequest(errors);
    } else if (error.statusCode === 429) {
      problem = problems.tooManyRequests(Number(reply.getHeader("retry-after") ?? 60));
    } else {
      request.log.error(error); // {w_c_hide}
      problem = problems.server();
    }
    reply.code(problem.status).type("application/problem+json");
    return reply.send(problem.body(request.url));
  });

  const store = createStore();
  await app.register(productRoutes(store), { prefix: "/v1" });
  await app.register(orderRoutes(store), { prefix: "/v1" });
  app.get("/openapi.json", { schema: { hide: true } }, async () => app.swagger());
  return app;
}
''',
    "src/server.ts": '''import { buildApp } from "./app.ts";

const port = Number(process.env.PORT ?? 3000);
const app = await buildApp({ rateLimit: Number(process.env.RATE_LIMIT ?? 100) });
await app.listen({ port });
console.log(`Listening on http://localhost:${port}`);
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => app.close());
''',
    "src/app.test.ts": '''import { test } from "node:test";
import assert from "node:assert/strict";
import { buildApp } from "./app.ts";

type ProductJson = { id: number; stock: number; price: { amount: number } };

test("{w_t_pages}", async () => {
  const app = await buildApp();
  const seen: number[] = [];
  let cursor: string | null = null;
  do {
    const url: string = `/v1/products?limit=5${cursor ? `&cursor=${cursor}` : ""}`;
    const page = (await app.inject(url)).json();
    seen.push(...page.data.map((p: ProductJson) => p.id));
    cursor = page.next_cursor;
  } while (cursor);
  assert.deepEqual(seen, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
});

test("{w_t_sorted}", async () => {
  const app = await buildApp();
  const page = (await app.inject("/v1/products?sort=-price&limit=3")).json();
  const prices = page.data.map((p: ProductJson) => p.price.amount);
  assert.deepEqual(prices, [45000, 30000, 21000]);
});

test("{w_t_replay}", async () => {
  const app = await buildApp();
  const order = {
    method: "POST" as const,
    url: "/v1/orders",
    headers: { "idempotency-key": "test-key-0001" },
    payload: { items: [{ product_id: 1, quantity: 2 }] },
  };
  const first = await app.inject(order);
  const second = await app.inject(order);
  assert.equal(first.statusCode, 201);
  assert.equal(second.headers["idempotent-replayed"], "true");
  assert.deepEqual(second.json(), first.json());
  assert.equal((await app.inject("/v1/products/1")).json().stock, 8);
});

test("{w_t_stale}", async () => {
  const app = await buildApp();
  const patch = (etag: string) =>
    app.inject({
      method: "PATCH",
      url: "/v1/products/2",
      headers: { "if-match": etag },
      payload: { stock: 3 },
    });
  assert.equal((await patch(\'"1"\')).statusCode, 200);
  assert.equal((await patch(\'"1"\')).statusCode, 412);
});

test("{w_t_invalid}", async () => {
  const app = await buildApp();
  const res = await app.inject({
    method: "POST",
    url: "/v1/orders",
    headers: { "idempotency-key": "test-key-0002" },
    payload: { items: [{ product_id: 1, quantity: 0 }], coupon: "FREE" },
  });
  assert.equal(res.statusCode, 422);
  assert.equal(res.headers["content-type"], "application/problem+json; charset=utf-8");
  assert.equal(res.json().errors.length, 2);
});
''',
    "demos/drift.ts": '''// Newest first, like "new arrivals". Page 1 is read, then a product is added.
type Row = { id: number };
// 6, 5, 4, 3, 2, 1
let rows: Row[] = Array.from({ length: 6 }, (_, i) => ({ id: 6 - i }));
const ids = (page: Row[]) => page.map((r) => r.id).join(", ");

const byOffset = (offset: number) => rows.slice(offset, offset + 3);
const byCursor = (after = Infinity) => rows.filter((r) => r.id < after).slice(0, 3);

const offsetPage1 = byOffset(0);
const cursorPage1 = byCursor();
rows = [{ id: 7 }, ...rows];
const cursorPage2 = byCursor(cursorPage1.at(-1)?.id);
console.log("{w_d_new} 7");
console.log(`{w_d_offset}: {w_d_page} 1 = ${ids(offsetPage1)} | {w_d_page} 2 = ${ids(byOffset(3))}`);
console.log(`{w_d_cursor}: {w_d_page} 1 = ${ids(cursorPage1)} | {w_d_page} 2 = ${ids(cursorPage2)}`);
''',
}


ANSWER_FILES = {
    "answers/search-demo.ts": '''import { buildApp } from "./src/app.ts";

const app = await buildApp();
for (const q of ["{w_q}", "x"]) {
  const res = await app.inject(`/v1/products?q=${encodeURIComponent(q)}&limit=1`);
  const body = res.json();
  console.log(res.statusCode, JSON.stringify(body.data?.map((p: { name: string }) => p.name) ?? body.errors));
  if (body.next_cursor) {
    const next = (await app.inject(`/v1/products?q=${encodeURIComponent(q)}&limit=1&cursor=${body.next_cursor}`)).json();
    console.log("next:", JSON.stringify(next.data.map((p: { name: string }) => p.name)));
  }
}
''',
    "answers/idempotency.ts": '''// Idempotency keys that belong to one client and expire, with a clock that tests can control.
export type Saved<T> = { fingerprint: string; result?: T; storedAt: number };

export class IdempotencyStore<T> {
  #entries = new Map<string, Saved<T>>();
  #ttl: number;
  #now: () => number;

  constructor(ttlMs = 24 * 60 * 60 * 1000, now = () => Date.now()) {
    this.#ttl = ttlMs;
    this.#now = now;
  }

  // The same key from two clients is two different keys.
  #id(client: string, key: string) {
    return `${client}:${key}`;
  }

  get(client: string, key: string): Saved<T> | undefined {
    const entry = this.#entries.get(this.#id(client, key));
    if (entry && this.#now() - entry.storedAt >= this.#ttl) {
      this.#entries.delete(this.#id(client, key));
      return undefined;
    }
    return entry;
  }

  set(client: string, key: string, fingerprint: string, result?: T) {
    this.#entries.set(this.#id(client, key), { fingerprint, result, storedAt: this.#now() });
  }

  delete(client: string, key: string) {
    this.#entries.delete(this.#id(client, key));
  }
}
''',
    "answers/idempotency.test.ts": '''import { test } from "node:test";
import assert from "node:assert/strict";
import { IdempotencyStore } from "./idempotency.ts";

test("keys belong to one client", () => {
  const store = new IdempotencyStore<number>();
  store.set("client-a", "key-1", "f1", 1);
  assert.equal(store.get("client-a", "key-1")?.result, 1);
  assert.equal(store.get("client-b", "key-1"), undefined);
});

test("keys expire after the time to live", () => {
  let now = 0;
  const store = new IdempotencyStore<number>(1000, () => now);
  store.set("client-a", "key-1", "f1", 1);
  now = 999;
  assert.equal(store.get("client-a", "key-1")?.result, 1);
  now = 1000;
  assert.equal(store.get("client-a", "key-1"), undefined);
});
''',
}

ANSWER_SEARCH = (
    ("  max_price: z.coerce.number().int().min(0).optional(),\n});",
     "  max_price: z.coerce.number().int().min(0).optional(),\n  q: z.string().trim().min(2).max(50).optional(),\n});"),
    ("        const { limit, cursor, sort, min_price, max_price } = request.query;",
     "        const { limit, cursor, sort, min_price, max_price, q } = request.query;"),
    ("          .filter((p) => max_price === undefined || p.price <= max_price)",
     "          .filter((p) => max_price === undefined || p.price <= max_price)\n"
     "          .filter((p) => !q || p.name.toLowerCase().includes(q.toLowerCase()))"),
)


def answers(folder, t):
    target = folder / "answers" / "src"
    shutil.copytree(folder / "src", target)
    route = target / "routes" / "products.ts"
    text = route.read_text()
    for old, new in ANSWER_SEARCH:
        assert old in text, old
        text = text.replace(old, new)
    route.write_text(text)
    for name, text in ANSWER_FILES.items():
        (folder / name).write_text(fill(text, t))
    s = Session(folder)
    s.run("node answers/search-demo.ts")
    s.run("node --test --test-reporter=spec answers/idempotency.test.ts 2>&1 | grep -E '✔|✖'")
    s.save(folder / "answers.sh")


def record(folder, t):
    s = Session(folder)
    base = "localhost:3000"
    with Server("node src/server.ts", folder, f"http://{base}/ready"):
        s.note(t["w_s_routes"])
        s.run(f"curl -s {base}/openapi.json | jq -r '.paths | to_entries[] | .key as $p "
              "| .value | keys[] | ascii_upcase + \" \" + $p'")
        s.save(folder / "routes.sh")

        s.note(t["w_s_first"])
        out = s.run(f"curl -s '{base}/v1/products?limit=3' | jq -c '(.data[] | [.id, .name, .price.amount]), .next_cursor'")
        cursor = out.strip().split("\n")[-1].strip('"')
        s.note(t["w_s_next"])
        s.run(f"curl -s '{base}/v1/products?limit=3&cursor={cursor}' | jq -c '(.data[] | [.id, .name, .price.amount]), .next_cursor'")
        s.note(t["w_s_filter"])
        out = s.run(f"curl -s '{base}/v1/products?limit=2&sort=-price&max_price=20000' "
                    "| jq -c '(.data[] | [.id, .price.amount]), .next_cursor'")
        cursor = out.strip().split("\n")[-1].strip('"')
        s.run(f"curl -s '{base}/v1/products?limit=2&sort=-price&max_price=20000&cursor={cursor}' "
              "| jq -c '(.data[] | [.id, .price.amount]), .next_cursor'")
        s.save(folder / "pages.sh")

        s.note(t["w_s_bad"])
        s.run(f"curl -s '{base}/v1/products?limit=500&sort=stock' | jq")
        s.save(folder / "bad-query.sh")

        s.note(t["w_s_read"])
        s.run(f"curl -si {base}/v1/products/2 | grep -iE '^(HTTP|etag)|^\\{{'")
        patch = f"curl -s -X PATCH {base}/v1/products/2 -H 'Content-Type: application/json' -d '{{\"price\": 6500}}'"
        s.note(t["w_s_no_match"])
        s.run(patch + " | jq -c")
        s.note(t["w_s_ok"])
        s.run(patch.replace("curl -s", "curl -si") + " -H 'If-Match: \"1\"' | grep -iE '^(HTTP|etag)|^\\{'")
        s.note(t["w_s_stale"])
        s.run(patch.replace("6500", "7000") + " -H 'If-Match: \"1\"' | jq -c")
        s.save(folder / "if-match.sh")

        order = (f"curl -si -X POST {base}/v1/orders -H 'Content-Type: application/json' "
                 "-H 'Idempotency-Key: 4f1c2a9e-order-0001' -d '{{\"items\": [{{\"product_id\": 1, \"quantity\": {q}}}]}}'")
        s.note(t["w_s_order"])
        s.run(order.format(q=2) + " | grep -iE '^(HTTP|location|idempotent)|^\\{'")
        s.note(t["w_s_again"])
        s.run(order.format(q=2) + " | grep -iE '^(HTTP|location|idempotent)|^\\{'")
        s.note(t["w_s_other"])
        s.run(order.format(q=3).replace("curl -si", "curl -s") + " | jq -c")
        s.note(t["w_s_stock_once"])
        s.run(f"curl -s {base}/v1/products/1 | jq -c '{{id, stock}}'")
        s.save(folder / "idempotency.sh")

        s.note(t["w_s_too_many"])
        s.run(order.format(q=50).replace("curl -si", "curl -s").replace("0001", "0002") + " | jq")
        s.note(t["w_s_cancel"])
        s.run(f"curl -s -X POST {base}/v1/orders/1/cancel | jq -c '{{id, status, total}}'")
        s.run(f"curl -s -X POST {base}/v1/orders/1/cancel | jq -c")
        s.save(folder / "orders.sh")

    env = os.environ.copy()
    with Server("RATE_LIMIT=3 node src/server.ts", folder, f"http://{base}/ready"):
        s.note(t["w_s_limit"])
        s.run(f"for i in 1 2 3; do curl -s -o /dev/null -w '%{{http_code}} ' {base}/v1/products/1; done; echo")
        s.run(f"curl -si {base}/v1/products/1 | grep -iE '^(HTTP|x-ratelimit|retry-after)|^\\{{'")
        s.save(folder / "rate-limit.sh")

    s.note(t["w_s_drift"])
    s.run("node demos/drift.ts")
    s.save(folder / "drift.sh")

    s.note(t["w_s_test"])
    s.run("npm test")
    s.save(folder / "test.sh")


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        names = re.findall(r'"([^"]+)"', t["w_names"])
        words = dict(t, w_names_list="\n".join(f'  "{n}",' for n in names))
        text = fill(text, words)
        if lang == "ar":
            for en, ar in COMMENTS_AR.items():
                text = text.replace(f"// {en}", f"// {ar}")
        path.write_text(text)
    os.symlink(B3 / "node_modules", folder / "node_modules")
    # The listings must fit the book's page: about 84 characters.
    subprocess.run(["npx", "prettier", "--print-width", "84", "--write", "src", "demos"], cwd=folder,
                   check=True, capture_output=True)
    record(folder, t)
    answers(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
