import type { Kysely } from "kysely";

// الخطوة 1، التوسيع: عمود جديد يجوز أن يكون فارغاً، فيبقى الكود القديم يعمل.
export async function up(db: Kysely<unknown>): Promise<void> {
  await db.schema.alterTable("products").addColumn("sku", "text").execute();
}

export async function down(db: Kysely<unknown>): Promise<void> {
  await db.schema.alterTable("products").dropColumn("sku").execute();
}
