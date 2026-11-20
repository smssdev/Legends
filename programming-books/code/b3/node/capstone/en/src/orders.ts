import { createHash } from "node:crypto";
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
          // the client's key makes a retry safe: the same key returns the same order
          headers: z.looseObject({ "idempotency-key": z.string().min(8).max(100) }),
        },
      },
      async (request, reply) => {
        const userId = request.userId!;
        const key = request.headers["idempotency-key"];
        const hash = createHash("sha256")
          .update(JSON.stringify(request.body))
          .digest("hex");

        // all or nothing: the order, its lines, the stock and the outbox row commit together
        const result = await db.transaction().execute(async (trx) => {
          const created = await trx
            .insertInto("orders")
            .values({ user_id: userId, idempotency_key: key, request_hash: hash })
            .onConflict((c) =>
              c.columns(["user_id", "idempotency_key"]).doNothing(),
            )
            .returning("id")
            .executeTakeFirst();
          if (!created) {
            // the key was used before: return that order, unless the body is different
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
            // the stock is taken only if it is enough, in the same statement
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
              .values({
                order_id: created.id,
                product_id,
                quantity,
                price: product.price,
              })
              .execute();
          }
          await trx
            .updateTable("orders")
            .set({ total })
            .where("id", "=", created.id)
            .execute();
          // the email is a row in the same transaction; the worker sends it after the commit
          await trx
            .insertInto("outbox")
            .values({
              topic: "order.placed",
              payload: JSON.stringify({ order_id: created.id }),
            })
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
