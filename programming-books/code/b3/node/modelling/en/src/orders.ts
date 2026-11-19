import { jsonArrayFrom } from "kysely/helpers/postgres";
import { db } from "./db.ts";

export async function findOrder(id: number) {
  // the result type is built from the selected columns
  return db
    .selectFrom("orders as o")
    .innerJoin("customers as c", "c.id", "o.customer_id")
    .select((eb) => [
      "o.id",
      "o.status",
      "c.name as customer",
      // the items as a JSON array, built by PostgreSQL in the same query
      jsonArrayFrom(
        eb
          .selectFrom("order_items as i")
          .innerJoin("products as p", "p.id", "i.product_id")
          .select(["p.name", "i.quantity", "i.price"])
          .whereRef("i.order_id", "=", "o.id"),
      ).as("items"),
    ])
    .where("o.id", "=", id)
    .executeTakeFirst();
}

// One query for the orders, then one more for EACH order: 1 + N.
export async function customerOrdersOneByOne(customerId: number) {
  const orders = await db
    .selectFrom("orders")
    .select(["id", "status"])
    .where("customer_id", "=", customerId)
    .execute();
  const result = [];
  for (const order of orders) {
    const items = await db
      .selectFrom("order_items")
      .select(["product_id", "quantity", "price"])
      .where("order_id", "=", order.id)
      .execute();
    result.push({ ...order, items });
  }
  return result;
}

// One query, whatever the number of orders.
export async function customerOrdersAtOnce(customerId: number) {
  return db
    .selectFrom("orders as o")
    .select((eb) => [
      "o.id",
      "o.status",
      jsonArrayFrom(
        eb
          .selectFrom("order_items as i")
          .select(["i.product_id", "i.quantity", "i.price"])
          .whereRef("i.order_id", "=", "o.id"),
      ).as("items"),
    ])
    .where("o.customer_id", "=", customerId)
    .execute();
}
