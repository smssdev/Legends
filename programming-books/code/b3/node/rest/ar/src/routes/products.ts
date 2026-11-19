import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import { messages } from "../messages.ts";
import { problems } from "../problem.ts";
import { egp, IdParams, ProductOut } from "../schemas.ts";
import type { Product, Store } from "../store.ts";

const SORTS = {
  id: "id",
  price: "price",
  "-price": "price",
  name: "name",
} as const;
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

// تُرتب الصفوف بحقل الترتيب ثم بالرقم، فيكون الترتيب كاملاً دائماً.
function compare(row: Product, [value, id]: Position, sort: Sort): number {
  const own = row[SORTS[sort]];
  const diff = own < value ? -1 : own > value ? 1 : row.id - id;
  return sort === "-price" ? -diff : diff;
}

// غامض للعملاء: base64url، فلا يصنع أحد المؤشرات بيده
const encode = (position: Position) =>
  Buffer.from(JSON.stringify(position)).toString("base64url");

function decode(cursor: string): Position {
  try {
    const position = JSON.parse(Buffer.from(cursor, "base64url").toString());
    if (Array.isArray(position) && position.length === 2)
      return position as Position;
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
          // المؤشر قيمة الترتيب ورقم آخر صف: الصفحة تبدأ بعده
          const after = decode(cursor);
          rows = rows.filter((p) => compare(p, after, sort) > 0);
        }
        const page = rows.slice(0, limit);
        const last = page.at(-1);
        const next =
          rows.length > limit && last ? encode([last[field], last.id]) : null;
        return { data: page.map(show), next_cursor: next };
      },
    );

    app.get(
      "/products/:id",
      {
        schema: { params: IdParams, response: { 200: ProductOut, 304: z.null() } },
      },
      async (request, reply) => {
        const product = find(request.params.id);
        const etag = `"${product.version}"`;
        reply.header("ETag", etag);
        if (request.headers["if-none-match"] === etag)
          return reply.code(304).send(null);
        return show(product);
      },
    );

    app.patch(
      "/products/:id",
      {
        schema: {
          params: IdParams,
          body: ProductPatch,
          response: { 200: ProductOut },
        },
      },
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
