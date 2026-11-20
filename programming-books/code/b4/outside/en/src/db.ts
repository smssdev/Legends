import pg from "pg";
import { config } from "./config.ts";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));
export const pool = new pg.Pool({ connectionString: config.databaseUrl });
