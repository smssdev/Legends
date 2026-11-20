import { type Kysely, sql } from "kysely";

// up: what this migration adds
export async function up(db: Kysely<unknown>): Promise<void> {
  await db.schema
    .createTable("customers")
    .addColumn("id", "bigint", (c) => c.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("name", "text", (c) => c.notNull())
    .addColumn("email", "text", (c) => c.notNull().unique())
    .addColumn("created_at", "timestamptz", (c) =>
      c.notNull().defaultTo(sql`now()`),
    )
    .execute();

  await db.schema
    .createTable("products")
    .addColumn("id", "bigint", (c) => c.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("name", "text", (c) => c.notNull())
    .addColumn("price", "integer", (c) => c.notNull().check(sql`price > 0`))
    .addColumn("stock", "integer", (c) =>
      c
        .notNull()
        .defaultTo(0)
        .check(sql`stock >= 0`),
    )
    .execute();

  await db.schema
    .createTable("orders")
    .addColumn("id", "bigint", (c) => c.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("customer_id", "bigint", (c) =>
      c.notNull().references("customers.id"),
    )
    .addColumn("status", "text", (c) =>
      c
        .notNull()
        .defaultTo("pending")
        .check(sql`status IN ('pending', 'paid', 'shipped', 'cancelled')`),
    )
    .addColumn("created_at", "timestamptz", (c) =>
      c.notNull().defaultTo(sql`now()`),
    )
    .execute();
  await db.schema
    .createIndex("orders_customer_id_idx")
    .on("orders")
    .column("customer_id")
    .execute();

  await db.schema
    .createTable("order_items")
    .addColumn("order_id", "bigint", (c) =>
      c.notNull().references("orders.id").onDelete("cascade"),
    )
    .addColumn("product_id", "bigint", (c) => c.notNull().references("products.id"))
    .addColumn("quantity", "integer", (c) =>
      c.notNull().check(sql`quantity BETWEEN 1 AND 99`),
    )
    .addColumn("price", "integer", (c) => c.notNull())
    .addPrimaryKeyConstraint("order_items_pkey", ["order_id", "product_id"])
    .execute();
}

// down: how to undo it exactly
export async function down(db: Kysely<unknown>): Promise<void> {
  for (const table of ["order_items", "orders", "products", "customers"]) {
    await db.schema.dropTable(table).execute();
  }
}
