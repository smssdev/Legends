import { promises as fs } from "node:fs";
import path from "node:path";
import { Kysely, PostgresDialect } from "kysely";
import { FileMigrationProvider, Migrator } from "kysely/migration";
import pg from "pg";

const db = new Kysely<unknown>({
  dialect: new PostgresDialect({
    pool: new pg.Pool({ connectionString: process.env.DATABASE_URL }),
  }),
});
const migrator = new Migrator({
  db,
  provider: new FileMigrationProvider({
    fs,
    path,
    migrationFolder: path.join(import.meta.dirname, "../migrations"),
  }),
});

const { error, results } =
  process.argv[2] === "down"
    ? await migrator.migrateDown()
    : await migrator.migrateToLatest();
for (const r of results ?? []) {
  console.log(`${r.status.padEnd(7)} ${r.direction.padEnd(4)} ${r.migrationName}`);
}
if (error) {
  console.error("migration failed:", error);
  process.exitCode = 1;
}
if (!results?.length) console.log("nothing to do");
await db.destroy();
