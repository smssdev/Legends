import rateLimit from "@fastify/rate-limit";
import Fastify, { type FastifyError } from "fastify";
import {
  hasZodFastifySchemaValidationErrors,
  serializerCompiler,
  validatorCompiler,
} from "fastify-type-provider-zod";
import type { Redis } from "ioredis";
import { type Kysely, sql } from "kysely";
import { authRoutes } from "./auth.ts";
import { config } from "./config.ts";
import type { DB } from "./db.ts";
import { measure } from "./metrics.ts";
import { orderRoutes } from "./orders.ts";
import { Problem, problems } from "./problem.ts";
import { productRoutes } from "./products.ts";

export type Deps = { db: Kysely<DB>; redis: Redis };

export async function buildApp(deps: Deps) {
  const app = Fastify({ logger: { level: config.LOG_LEVEL } });
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);
  await app.register(rateLimit, { global: false, redis: deps.redis });

  app.setErrorHandler((error: FastifyError, request, reply) => {
    let problem: Problem;
    if (error instanceof Problem) {
      problem = error;
    } else if (hasZodFastifySchemaValidationErrors(error)) {
      problem = problems.invalid(
        error.validation.map((issue) => ({
          field: [error.validationContext, ...String(issue.instancePath).split("/")]
            .filter(Boolean)
            .join("."),
          message: issue.message ?? "",
        })),
      );
    } else if (error.statusCode === 429) {
      problem = problems.tooMany(Number(reply.getHeader("retry-after") ?? 60));
    } else {
      request.log.error(error);
      problem = problems.server();
    }
    reply.code(problem.status).type("application/problem+json");
    return reply.send(problem.body(request.url));
  });

  measure(app);
  await app.register(authRoutes(deps));
  await app.register(productRoutes(deps));
  await app.register(orderRoutes(deps));

  app.get("/health", async () => ({ ok: true }));
  // الجاهزية أن تجيب قاعدة البيانات وRedis معاً
  app.get("/ready", async (_request, reply) => {
    try {
      await sql`SELECT 1`.execute(deps.db);
      await deps.redis.ping();
      return { ready: true };
    } catch {
      return reply.code(503).send({ ready: false });
    }
  });
  return app;
}
