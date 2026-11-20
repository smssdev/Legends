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
    .max(20)
    .refine(
      (items) => new Set(items.map((i) => i.product_id)).size === items.length,
      {
        error: "كل منتج مرة واحدة على الأكثر",
      },
    ),
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
          // مفتاح العميل يجعل إعادة المحاولة آمنة: المفتاح نفسه يعيد الطلب نفسه
          headers: z.looseObject({ "idempotency-key": z.string().min(8).max(100) }),
        },
      },
      async (request, reply) => {
        const userId = request.userId!;
        const key = request.headers["idempotency-key"];
        const hash = createHash("sha256")
          .update(JSON.stringify(request.body))
          .digest("hex");

        // الكل أو لا شيء: الطلب وبنوده والمخزون وصف الصندوق الصادر تُعتمد معاً
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
            // المفتاح استُعمل من قبل: أعد ذلك الطلب، إلا إن اختلف الجسم
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
            // لا يؤخذ المخزون إلا إن كفى، في الجملة نفسها
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
          // البريد صف في المعاملة نفسها؛ والعامل يرسله بعد الاعتماد
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
