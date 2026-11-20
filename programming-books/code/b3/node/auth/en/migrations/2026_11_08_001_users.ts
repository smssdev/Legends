import { type Kysely, sql } from "kysely";

export async function up(db: Kysely<unknown>): Promise<void> {
  await db.schema
    .createTable("users")
    .addColumn("id", "bigint", (c) => c.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("email", "text", (c) => c.notNull())
    .addColumn("name", "text", (c) => c.notNull())
    .addColumn("password_hash", "text", (c) => c.notNull())
    .addColumn("role", "text", (c) =>
      c
        .notNull()
        .defaultTo("customer")
        .check(sql`role IN ('customer', 'admin')`),
    )
    .addColumn("created_at", "timestamptz", (c) =>
      c.notNull().defaultTo(sql`now()`),
    )
    .execute();
  // one account per email, whatever its capitals
  await db.schema
    .createIndex("users_email_key")
    .on("users")
    .unique()
    .expression(sql`lower(email)`)
    .execute();

  await db.schema
    .createTable("sessions")
    .addColumn("token_hash", "text", (c) => c.primaryKey())
    .addColumn("user_id", "bigint", (c) =>
      c.notNull().references("users.id").onDelete("cascade"),
    )
    .addColumn("created_at", "timestamptz", (c) =>
      c.notNull().defaultTo(sql`now()`),
    )
    .addColumn("expires_at", "timestamptz", (c) => c.notNull())
    .execute();
  await db.schema
    .createIndex("sessions_user_id_idx")
    .on("sessions")
    .column("user_id")
    .execute();

  await db.schema
    .createTable("orders")
    .addColumn("id", "bigint", (c) => c.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("user_id", "bigint", (c) => c.notNull().references("users.id"))
    .addColumn("total", "integer", (c) => c.notNull())
    .addColumn("created_at", "timestamptz", (c) =>
      c.notNull().defaultTo(sql`now()`),
    )
    .execute();
  await db.schema
    .createIndex("orders_user_id_idx")
    .on("orders")
    .column("user_id")
    .execute();
}

export async function down(db: Kysely<unknown>): Promise<void> {
  for (const table of ["orders", "sessions", "users"]) {
    await db.schema.dropTable(table).execute();
  }
}
