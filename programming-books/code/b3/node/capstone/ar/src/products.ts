import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
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
    throw problems.invalid([
      { field: "querystring.cursor", message: "مؤشر غير صالح" },
    ]);
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
          // المؤشر هو سعر آخر صف ورقمه؛ والفهرس (price, id) يجد من أين يبدأ
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
          next_cursor:
            rows.length > limit && last ? encode(last.price, last.id) : null,
        };
      },
    );
  };
