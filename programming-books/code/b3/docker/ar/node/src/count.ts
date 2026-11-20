import pg from "pg";

const db = new pg.Client({ connectionString: process.env.DATABASE_URL });
await db.connect();
const { rows } = await db.query("SELECT count(*)::int AS products FROM products");
console.log(rows[0]);
await db.end();
