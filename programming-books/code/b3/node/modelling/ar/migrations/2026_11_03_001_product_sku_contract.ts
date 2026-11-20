import { type Kysely, sql } from "kysely";

export async function up(db: Kysely<unknown>): Promise<void> {
  // الخطوة 2: املأ العمود لكل صف موجود.
  await sql`UPDATE products SET sku = 'BIT-' || lpad(id::text, 4, '0') WHERE sku IS NULL`.execute(
    db,
  );
  // الخطوة 3، التقليص: الآن لكل صف رمز SKU، فاجعله إلزامياً وفريداً.
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
