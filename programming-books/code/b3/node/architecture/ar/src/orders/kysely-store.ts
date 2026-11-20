import type { Kysely } from "kysely";
import type { DB } from "../db.ts";
import { OutOfStock, totalOf, UnknownProduct, type Line } from "./order.ts";
import type { OrderStore } from "./ports.ts";

// محوّل: المنفذ OrderStore، مطبَّقاً بـ Kysely وPostgreSQL
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
            throw exists
              ? new OutOfStock("المخزون لا يكفي")
              : new UnknownProduct("منتج مجهول");
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
          .values(
            lines.map((l) => ({
              order_id: id,
              product_id: l.productId,
              quantity: l.quantity,
              price: l.price,
            })),
          )
          .execute();
        return { id, email, lines, total, placedAt };
      }),
  };
}
