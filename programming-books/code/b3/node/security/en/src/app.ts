import Fastify, { type FastifyError } from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import { serializerCompiler, validatorCompiler } from "fastify-type-provider-zod";
import { config } from "./config.ts";
import { fileRoutes } from "./routes/files.ts";
import { searchRoutes } from "./routes/search.ts";
import { userRoutes } from "./routes/users.ts";

export async function buildApp() {
  // bodies above 100 KB are refused before they are read
  const app = Fastify({ bodyLimit: 100 * 1024 });
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  // security headers on every response
  await app.register(helmet);
  // browsers may call this API only from the shop's own website
  await app.register(cors, {
    origin: [config.ALLOWED_ORIGIN],
    methods: ["GET", "PATCH"],
  });

  const titles: Record<number, string> = {
    404: "Not found",
    413: "Body too large",
    422: "Invalid body",
  };
  app.setErrorHandler((error: FastifyError, request, reply) => {
    // a missing file is a 404, a body that fails its schema a 422 (as in Chapter 3)
    const status =
      error.code === "ENOENT"
        ? 404
        : error.validation
          ? 422
          : (error.statusCode ?? 500);
    // the details stay in the log; the client learns nothing about the code
    if (status >= 500) request.log.error(error);
    return reply
      .code(status)
      .send({ title: titles[status] ?? "Server error", status });
  });

  app.setNotFoundHandler((request, reply) =>
    reply.code(404).send({ title: "Not found", status: 404 }),
  );

  await app.register(searchRoutes);
  await app.register(userRoutes);
  await app.register(fileRoutes);
  return app;
}
