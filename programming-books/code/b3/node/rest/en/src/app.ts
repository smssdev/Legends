import Fastify, { type FastifyError } from "fastify";
import rateLimit from "@fastify/rate-limit";
import swagger from "@fastify/swagger";
import {
  hasZodFastifySchemaValidationErrors,
  jsonSchemaTransform,
  serializerCompiler,
  validatorCompiler,
} from "fastify-type-provider-zod";
import { Problem, problems } from "./problem.ts";
import { orderRoutes } from "./routes/orders.ts";
import { productRoutes } from "./routes/products.ts";
import { createStore } from "./store.ts";

export async function buildApp(options: { rateLimit?: number } = {}) {
  const app = Fastify();
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  await app.register(swagger, {
    openapi: {
      info: {
        title: "Bit's shop API",
        description: "Products and orders. Money is in piastres; times are UTC.",
        version: "1.0.0",
      },
    },
    transform: jsonSchemaTransform,
  });
  await app.register(rateLimit, {
    max: options.rateLimit ?? 100,
    timeWindow: "1 minute",
  });

  app.setErrorHandler((error: FastifyError, request, reply) => {
    let problem: Problem;
    if (error instanceof Problem) {
      problem = error;
    } else if (hasZodFastifySchemaValidationErrors(error)) {
      const where = error.validationContext ?? "body";
      const errors = error.validation.map((issue) => ({
        field: [
          where,
          ...String(issue.instancePath).split("/").filter(Boolean),
        ].join("."),
        message: issue.message ?? "",
      }));
      // 422: a well-formed body with wrong values
      // 400: a bad query, path or header: the request itself is malformed
      problem =
        where === "body"
          ? problems.invalidBody(errors)
          : problems.invalidRequest(errors);
    } else if (error.statusCode === 429) {
      problem = problems.tooManyRequests(
        Number(reply.getHeader("retry-after") ?? 60),
      );
    } else {
      request.log.error(error); // the details stay in the log
      problem = problems.server();
    }
    reply.code(problem.status).type("application/problem+json");
    return reply.send(problem.body(request.url));
  });

  const store = createStore();
  await app.register(productRoutes(store), { prefix: "/v1" });
  await app.register(orderRoutes(store), { prefix: "/v1" });
  app.get("/openapi.json", { schema: { hide: true } }, async () => app.swagger());
  return app;
}
