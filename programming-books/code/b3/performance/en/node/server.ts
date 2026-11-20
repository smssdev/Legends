import { pbkdf2, pbkdf2Sync } from "node:crypto";
import { promisify } from "node:util";
import Fastify from "fastify";
import pg from "pg";

// at most 10 connections: requests beyond that wait for one
const db = new pg.Pool({
  connectionString: "postgres://bit:secret@localhost:5432/shop",
  max: 10,
});
const app = Fastify();

app.get<{ Querystring: { category: string } }>("/products", async (request) => {
  const { rows } = await db.query(
    "SELECT id, name, price FROM products WHERE category = $1 ORDER BY price LIMIT 20",
    [request.query.category],
  );
  return rows;
});

app.get("/ping", async () => ({ ok: true }));

app.get("/hash/sync", async () => {
  // DANGER: 100,000 rounds of hashing on the event loop: nothing else runs meanwhile
  const key = pbkdf2Sync("password", "salt", 100_000, 32, "sha256");
  return { key: key.toString("hex").slice(0, 8) };
});

const pbkdf2Async = promisify(pbkdf2);
app.get("/hash/async", async () => {
  // the same work on libuv's thread pool: the event loop stays free
  const key = await pbkdf2Async("password", "salt", 100_000, 32, "sha256");
  return { key: key.toString("hex").slice(0, 8) };
});

await app.listen({ port: 3000 });
