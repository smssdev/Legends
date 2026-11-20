import Fastify, { type FastifyError } from "fastify";
import rateLimit from "@fastify/rate-limit";
import {
  hasZodFastifySchemaValidationErrors,
  serializerCompiler,
  validatorCompiler,
} from "fastify-type-provider-zod";
import { Problem, problems } from "./problem.ts";
import { authRoutes } from "./routes/auth.ts";
import { orderRoutes } from "./routes/orders.ts";

export async function buildApp() {
  const app = Fastify();
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);
  // only routes that ask for it are limited (here: login)
  await app.register(rateLimit, { global: false });

  app.setErrorHandler((error: FastifyError, request, reply) => {
    let problem: Problem;
    if (error instanceof Problem) {
      problem = error;
    } else if (hasZodFastifySchemaValidationErrors(error)) {
      problem = problems.invalid(
        error.validation.map((issue) => ({
          field: String(issue.instancePath).split("/").filter(Boolean).join("."),
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

  await app.register(authRoutes);
  await app.register(orderRoutes);
  app.get("/ready", async () => ({ ready: true }));
  return app;
}
