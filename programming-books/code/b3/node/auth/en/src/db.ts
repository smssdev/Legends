import { Kysely, PostgresDialect } from "kysely";
import pg from "pg";
import type { DB } from "./db-types.ts";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

export const db = new Kysely<DB>({
  dialect: new PostgresDialect({
    pool: new pg.Pool({ connectionString: process.env.DATABASE_URL }),
  }),
});
