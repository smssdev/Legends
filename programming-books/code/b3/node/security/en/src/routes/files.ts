import { readFile } from "node:fs/promises";
import path from "node:path";
import type { FastifyPluginAsync } from "fastify";

const folder = path.join(import.meta.dirname, "../../public");

export const fileRoutes: FastifyPluginAsync = async (app) => {
  app.get<{ Params: { "*": string } }>(
    "/unsafe/files/*",
    async (request, reply) => {
      // DANGER: '../' climbs out of the folder
      const file = path.join(folder, request.params["*"]);
      return reply.type("text/plain").send(await readFile(file, "utf8"));
    },
  );

  app.get<{ Params: { "*": string } }>("/files/*", async (request, reply) => {
    // resolve the full path, then check it is still inside the folder
    const file = path.resolve(folder, request.params["*"]);
    if (!file.startsWith(folder + path.sep)) return reply.callNotFound();
    return reply.type("text/plain").send(await readFile(file, "utf8"));
  });
};
