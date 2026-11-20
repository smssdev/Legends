import Fastify from "fastify";
import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));
const db = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const app = Fastify({ logger: true });

app.get("/health", async () => ({ status: "ok" }));
app.get("/products", async () => (await db.query("SELECT * FROM products ORDER BY id")).rows);

await app.listen({ host: "0.0.0.0", port: Number(process.env.PORT ?? 3000) });
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => app.close());
