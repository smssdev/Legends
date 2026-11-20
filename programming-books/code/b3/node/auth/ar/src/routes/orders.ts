import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import { authenticate, currentUser, requireRole } from "../auth.ts";
import { db } from "../db.ts";
import { problems } from "../problem.ts";

export const orderRoutes: FastifyPluginAsyncZod = async (app) => {
  // every route in this plugin needs a signed-in user
  app.addHook("onRequest", authenticate);

  app.get("/orders", async (request) =>
    db
      .selectFrom("orders")
      .select(["id", "total"])
      .where("user_id", "=", currentUser(request).id)
      .orderBy("id")
      .execute(),
  );

  app.get(
    "/orders/:id",
    { schema: { params: z.object({ id: z.coerce.number().int() }) } },
    async (request) => {
      const user = currentUser(request);
      const order = await db
        .selectFrom("orders")
        .selectAll()
        .where("id", "=", request.params.id)
        .executeTakeFirst();
      // طلب غيرك «غير موجود» لا «غير مسموح»: لا يُكشف وجوده
      if (!order || (order.user_id !== user.id && user.role !== "admin")) {
        throw problems.noOrder(request.params.id);
      }
      return order;
    },
  );

  app.get("/admin/users", { preHandler: requireRole("admin") }, async () =>
    db.selectFrom("users").select(["id", "email", "role"]).orderBy("id").execute(),
  );
};
