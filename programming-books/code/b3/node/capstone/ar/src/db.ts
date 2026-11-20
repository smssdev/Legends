import { type Generated, Kysely, PostgresDialect } from "kysely";
import pg from "pg";
import { config } from "./config.ts";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

export type DB = {
  users: { id: Generated<number>; email: string; password_hash: string };
  sessions: { token_hash: string; user_id: number; expires_at: Date };
  products: { id: Generated<number>; name: string; price: number; stock: number };
  orders: {
    id: Generated<number>;
    user_id: number;
    idempotency_key: string;
    request_hash: string;
    total: Generated<number>;
    created_at: Generated<Date>;
  };
  order_items: {
    order_id: number;
    product_id: number;
    quantity: number;
    price: number;
  };
  outbox: {
    id: Generated<number>;
    topic: string;
    payload: unknown;
    sent_at: Date | null;
  };
};

export const connect = () =>
  new Kysely<DB>({
    dialect: new PostgresDialect({
      pool: new pg.Pool({ connectionString: config.DATABASE_URL, max: 10 }),
    }),
  });
