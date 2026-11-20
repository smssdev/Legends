import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import { db } from "../db.ts";

const Id = z.object({ id: z.coerce.number().int() });
const show = "RETURNING id, name, role";

export const userRoutes: FastifyPluginAsyncZod = async (app) => {
  app.patch(
    "/unsafe/users/:id",
    { schema: { params: Id, body: z.record(z.string(), z.string()) } },
    async (request) => {
      // DANGER: every field the client sends is written, role included
      const fields = Object.keys(request.body);
      const set = fields.map((f, i) => `"${f}" = $${i + 2}`).join(", ");
      const values = [request.params.id, ...Object.values(request.body)];
      const sql = `UPDATE users SET ${set} WHERE id = $1 ${show}`;
      return (await db.query(sql, values)).rows[0];
    },
  );

  app.patch(
    "/users/:id",
    {
      schema: {
        params: Id,
        // only the fields a customer may change; any other key is refused
        body: z.strictObject({ name: z.string().trim().min(1).max(100) }),
      },
    },
    async (request) => {
      const sql = `UPDATE users SET name = $2 WHERE id = $1 ${show}`;
      return (await db.query(sql, [request.params.id, request.body.name])).rows[0];
    },
  );
};
