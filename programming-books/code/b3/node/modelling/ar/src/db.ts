import { Kysely, PostgresDialect } from "kysely";
import pg from "pg";
import type { DB } from "./db-types.ts";

// أرقام bigint أعداداً: دقيقة حتى 2^53، أكثر بكثير مما سيحتاجه أي متجر
pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

// الاتصال في مكان واحد، وDB يصف كل جدول، مولَّداً من قاعدة البيانات.
export let queries = 0; // كل استعلام يرسله التطبيق، معدوداً (ومطبوعاً مع DEBUG_SQL=1)
export const db = new Kysely<DB>({
  dialect: new PostgresDialect({
    pool: new pg.Pool({ connectionString: process.env.DATABASE_URL }),
  }),
  log(event) {
    if (event.level === "query") {
      queries++;
      if (process.env.DEBUG_SQL)
        console.log(event.query.sql, event.query.parameters);
    }
  },
});
