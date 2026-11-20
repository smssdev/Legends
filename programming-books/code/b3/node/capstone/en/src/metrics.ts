import type { FastifyInstance } from "fastify";
import client from "prom-client";

// requests by route and status, and how long they took
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

export function measure(app: FastifyInstance) {
  app.addHook("onResponse", async (request, reply) => {
    const route = request.routeOptions.url ?? "unknown";
    if (["/health", "/ready", "/metrics"].includes(route)) return;
    requests.inc({ method: request.method, route, status: reply.statusCode });
    duration.observe({ route }, reply.elapsedTime / 1000);
  });
  app.get("/metrics", async (_request, reply) =>
    reply.type(client.register.contentType).send(await client.register.metrics()),
  );
}
