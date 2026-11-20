import Fastify, { type FastifyError } from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import { serializerCompiler, validatorCompiler } from "fastify-type-provider-zod";
import { config } from "./config.ts";
import { fileRoutes } from "./routes/files.ts";
import { searchRoutes } from "./routes/search.ts";
import { userRoutes } from "./routes/users.ts";

export async function buildApp() {
  // الأجسام فوق 100 KB تُرفض قبل قراءتها
  const app = Fastify({ bodyLimit: 100 * 1024 });
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  // ترويسات أمان مع كل استجابة
  await app.register(helmet);
  // المتصفحات تستدعي هذا API من موقع المتجر وحده
  await app.register(cors, {
    origin: [config.ALLOWED_ORIGIN],
    methods: ["GET", "PATCH"],
  });

  const titles: Record<number, string> = {
    404: "غير موجود",
    413: "الجسم أكبر من اللازم",
    422: "جسم غير صالح",
  };
  app.setErrorHandler((error: FastifyError, request, reply) => {
    // الملف المفقود 404، والجسم الذي يخالف مخططه 422 (كما في الفصل 3)
    const status =
      error.code === "ENOENT"
        ? 404
        : error.validation
          ? 422
          : (error.statusCode ?? 500);
    // التفاصيل تبقى في السجل؛ والعميل لا يعرف شيئاً عن الكود
    if (status >= 500) request.log.error(error);
    return reply
      .code(status)
      .send({ title: titles[status] ?? "خطأ في الخادم", status });
  });

  app.setNotFoundHandler((request, reply) =>
    reply.code(404).send({ title: "غير موجود", status: 404 }),
  );

  await app.register(searchRoutes);
  await app.register(userRoutes);
  await app.register(fileRoutes);
  return app;
}
