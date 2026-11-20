import Fastify from "fastify";
import type { Kysely } from "kysely";
import type { DB } from "./db.ts";
import { total } from "./pricing.ts";

export type Mailer = { send(to: string, subject: string): Promise<void> };

// مرسل البريد يُمرَّر، فتعطي الاختبارات بديلاً
export function buildApp(db: Kysely<DB>, mailer: Mailer) {
  const app = Fastify();

  app.post<{
    Body: { email: string; productId: number; quantity: number; code?: string };
  }>("/orders", async (request, reply) => {
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
  });
  return app;
}
