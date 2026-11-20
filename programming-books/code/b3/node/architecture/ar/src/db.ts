import { type Generated, Kysely, PostgresDialect } from "kysely";
import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

export type DB = {
  products: { id: number; name: string; price: number; stock: number };
  orders: { id: Generated<number>; email: string; total: number; placed_at: Date };
  order_items: {
    order_id: number;
    product_id: number;
    quantity: number;
    price: number;
  };
};

export const connect = () =>
  new Kysely<DB>({
    dialect: new PostgresDialect({
      pool: new pg.Pool({ connectionString: process.env.DATABASE_URL }),
    }),
  });
