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
  // كائن JSON واحد في كل سطر: تستطيع الآلات البحث فيه، ويستطيع الناس قراءته
  logger: {
    base: { service: `shop:${port}` },
    timestamp: () => `,"time":"${new Date().toISOString().slice(11, 23)}"`,
    formatters: {
      level: (label) => ({ level: label }),
      log: (line) => ({ ...line, responseTime: round(line.responseTime) }),
    },
    // المفيد وحده: الطريقة والعنوان، لا كل ترويسة
    serializers: {
      req: (req) => ({ method: req.method, url: req.url }),
      res: (res) => ({ status: res.statusCode }),
      err: (err) => ({ type: err.name, message: err.message, at: where(err) }),
    },
  },
  // رقم التتبع يأتي من ترويسة traceparent عند المنادي، أو يبدأ هنا
  genReqId: (req) => String(req.headers.traceparent ?? "").split("-")[1] ?? hex(16),
});

// الطلبات بالمسار والحالة، وكم استغرقت، ليجمعها Prometheus
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
  // نمط المسار، لا العنوان: /products/1 و/products/2 سلسلة واحدة
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
  // الخدمة التالية تأخذ رقم التتبع نفسه، فتنضم سجلاتها إلى سجلات هذا الطلب
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

// يأخذ العميل عنواناً ورقم التتبع ليذكره؛ والتفاصيل تذهب إلى السجل
app.setErrorHandler((err, request, reply) => {
  request.log.error({ err }, err.message);
  return reply.code(500).send({ title: "Server error", trace: request.id });
});

// انقطاع اتصال بقاعدة البيانات يُسجَّل، ولا يُسمح له بإسقاط العملية
db.on("error", (err) => app.log.warn({ err }, "database connection lost"));

// حي: العملية تجيب (أعد تشغيلها إن لم تجب)
app.get("/health", { logLevel: "silent" }, async () => ({ status: "ok" }));
// جاهز: يستطيع أداء عمله، فأرسل إليه الزيارات (وتوقف إن لم يكن)
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
