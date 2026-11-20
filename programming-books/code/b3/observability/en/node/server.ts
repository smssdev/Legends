import { randomBytes } from "node:crypto";
import Fastify from "fastify";
import pg from "pg";
import client from "prom-client";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));
const db = new pg.Pool({
  connectionString: "postgres://bit:secret@localhost:5432/shop",
});
const port = Number(process.env.PORT ?? 3000);
const hex = (bytes: number) => randomBytes(bytes).toString("hex");
const round = (ms: unknown) =>
  typeof ms === "number" ? Math.round(ms * 100) / 100 : undefined;
// the file and line where the error was thrown, without the whole stack
const where = (err: Error) => /([^/\s]+:\d+):\d+\)?$/m.exec(err.stack ?? "")?.[1];

const app = Fastify({
  // one JSON object per line: machines can search it, people can still read it
  logger: {
    base: { service: `shop:${port}` },
    timestamp: () => `,"time":"${new Date().toISOString().slice(11, 23)}"`,
    formatters: {
      level: (label) => ({ level: label }),
      log: (line) => ({ ...line, responseTime: round(line.responseTime) }),
    },
    // only what is useful: the method and the address, not every header
    serializers: {
      req: (req) => ({ method: req.method, url: req.url }),
      res: (res) => ({ status: res.statusCode }),
      err: (err) => ({ type: err.name, message: err.message, at: where(err) }),
    },
  },
  // the trace id comes from the caller's traceparent header, or starts here
  genReqId: (req) => String(req.headers.traceparent ?? "").split("-")[1] ?? hex(16),
});

// requests by route and status, and how long they took, for Prometheus to collect
const requests = new client.Counter({
  name: "http_requests_total",
  help: "Requests by route and status",
  labelNames: ["method", "route", "status"],
});
const duration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "How long requests took",
  labelNames: ["route"],
  buckets: [0.01, 0.05, 0.1, 0.5, 1],
});
app.addHook("onResponse", async (request, reply) => {
  // the route's pattern, not the address: /products/1 and /products/2 are one series
  const route = request.routeOptions.url ?? "unknown";
  if (["/health", "/ready", "/metrics"].includes(route)) return;
  requests.inc({ method: request.method, route, status: reply.statusCode });
  duration.observe({ route }, reply.elapsedTime / 1000);
});

app.get<{ Params: { id: string } }>("/products/:id", async (request, reply) => {
  const { rows } = await db.query(
    "SELECT id, name, price FROM products WHERE id = $1",
    [request.params.id],
  );
  return rows[0] ?? reply.code(404).send({ title: "Not found" });
});

app.get<{ Params: { id: string } }>("/stock/:id", async (request) => {
  const { rows } = await db.query("SELECT stock FROM products WHERE id = $1", [
    request.params.id,
  ]);
  return { stock: rows[0]?.stock ?? 0 };
});

app.get("/checkout", async (request) => {
  request.log.info("checkout started");
  // the next service gets the same trace id, so its logs join this request's
  const res = await fetch(`http://localhost:${process.env.STOCK_PORT}/stock/1`, {
    headers: { traceparent: `00-${request.id}-${hex(8)}-01` },
  });
  const { stock } = (await res.json()) as { stock: number };
  request.log.info({ stock }, "stock checked");
  return { ok: stock > 0 };
});

app.get("/boom", async () => {
  throw new Error("payment provider timed out");
});

// the client gets a title and the trace id to quote; the details go to the log
app.setErrorHandler((err, request, reply) => {
  request.log.error({ err }, err.message);
  return reply.code(500).send({ title: "Server error", trace: request.id });
});

// a dropped database connection is logged, not allowed to crash the process
db.on("error", (err) => app.log.warn({ err }, "database connection lost"));

// alive: the process answers (restart it if not)
app.get("/health", { logLevel: "silent" }, async () => ({ status: "ok" }));
// ready: it can do its job, so send it traffic (stop sending if not)
app.get("/ready", { logLevel: "silent" }, async (request, reply) => {
  try {
    await db.query({ text: "SELECT 1", query_timeout: 1000 });
    return { status: "ready" };
  } catch {
    return reply.code(503).send({ status: "database unavailable" });
  }
});

app.get("/metrics", { logLevel: "silent" }, async (_request, reply) =>
  reply.type(client.register.contentType).send(await client.register.metrics()),
);

await app.listen({ port });
