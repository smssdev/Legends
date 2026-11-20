import { readFile } from "node:fs/promises";
import path from "node:path";
import type { FastifyPluginAsync } from "fastify";

const folder = path.join(import.meta.dirname, "../../public");

export const fileRoutes: FastifyPluginAsync = async (app) => {
  app.get<{ Params: { "*": string } }>(
    "/unsafe/files/*",
    async (request, reply) => {
      // خطر: '../' تصعد خارج المجلد
      const file = path.join(folder, request.params["*"]);
      return reply.type("text/plain").send(await readFile(file, "utf8"));
    },
  );

  app.get<{ Params: { "*": string } }>("/files/*", async (request, reply) => {
    // احسب المسار الكامل، ثم تحقق أنه ما زال داخل المجلد
    const file = path.resolve(folder, request.params["*"]);
    if (!file.startsWith(folder + path.sep)) return reply.callNotFound();
    return reply.type("text/plain").send(await readFile(file, "utf8"));
  });
};
