import pg from "pg";
import { hashPassword } from "./lib/password.ts";

const db = new pg.Client({ connectionString: process.env.DATABASE_URL });
await db.connect();
const hash = await hashPassword("a long password");
const users = [
  ["owner@bithair.example", "owner", 1],
  ["omar@bithair.example", "staff", 1],
  ["hana@nourclinic.example", "owner", 2],
];
for (const [email, role, business] of users) {
  await db.query(
    `INSERT INTO users (email, password_hash, role, business_id)
     VALUES ($1, $2, $3, $4)`,
    [email, hash, role, business],
  );
}
await db.end();
