// server-only: importing this file from a Client Component fails the build
import "server-only";
import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

// one pool per process, kept on globalThis: Next reloads modules in development
const saved = globalThis as unknown as { pool?: pg.Pool };
export const pool = (saved.pool ??= new pg.Pool({
  connectionString: process.env.DATABASE_URL,
}));
