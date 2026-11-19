import { type Kysely, sql } from "kysely";

export async function up(db: Kysely<unknown>): Promise<void> {
  // Step 2: fill the column for every existing row.
  await sql`UPDATE products SET sku = 'BIT-' || lpad(id::text, 4, '0') WHERE sku IS NULL`.execute(
    db,
  );
  // Step 3, contract: now every row has a SKU, make it required and unique.
  await db.schema
    .alterTable("products")
    .alterColumn("sku", (c) => c.setNotNull())
    .execute();
  await db.schema
    .createIndex("products_sku_key")
    .on("products")
    .column("sku")
    .unique()
    .execute();
}

export async function down(db: Kysely<unknown>): Promise<void> {
  await db.schema.dropIndex("products_sku_key").execute();
  await db.schema
    .alterTable("products")
    .alterColumn("sku", (c) => c.dropNotNull())
    .execute();
}
