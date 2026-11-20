import { type Generated, Kysely, PostgresDialect } from "kysely";
import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

export type DB = {
  products: { id: number; name: string; price: number; stock: number };
  orders: { id: Generated<number>; email: string; total: number };
};

export function connect(schema = "public") {
  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    options: `-c search_path=${schema}`,
  });
  return new Kysely<DB>({ dialect: new PostgresDialect({ pool }) });
}

export const SCHEMA = `
  CREATE TABLE products (id bigint PRIMARY KEY, name text NOT NULL,
    price integer NOT NULL, stock integer NOT NULL CHECK (stock >= 0));
  CREATE TABLE orders (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text NOT NULL, total integer NOT NULL);`;
