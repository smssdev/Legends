import type { Kysely } from "kysely";

// Step 1, expand: a new column that may be empty, so old code keeps working.
export async function up(db: Kysely<unknown>): Promise<void> {
  await db.schema.alterTable("products").addColumn("sku", "text").execute();
}

export async function down(db: Kysely<unknown>): Promise<void> {
  await db.schema.alterTable("products").dropColumn("sku").execute();
}
