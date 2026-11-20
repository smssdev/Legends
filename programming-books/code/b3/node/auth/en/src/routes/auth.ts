import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { sql } from "kysely";
import { z } from "zod";
import { authenticate, currentUser } from "../auth.ts";
import { db } from "../db.ts";
import { hashPassword, verifyPassword } from "../password.ts";
import { problems } from "../problem.ts";
import { endSession, startSession } from "../sessions.ts";

const UserOut = z.object({
  id: z.number(),
  email: z.string(),
  name: z.string(),
  role: z.string(),
});
const Email = z.email().max(254).toLowerCase();
const Login = z.strictObject({ email: Email, password: z.string().max(128) });
// an unknown email still costs one hash, so the response time does not reveal which emails exist
const DUMMY = await hashPassword("not anyone's password");

export const authRoutes: FastifyPluginAsyncZod = async (app) => {
  app.post(
    "/auth/register",
    {
      schema: {
        body: z.strictObject({
          email: Email,
          name: z.string().trim().min(1).max(100),
          password: z.string().min(12).max(128),
        }),
        response: { 201: UserOut },
      },
    },
    async (request, reply) => {
      const { email, name, password } = request.body;
      const user = await db
        .insertInto("users")
        .values({ email, name, password_hash: await hashPassword(password) })
        .onConflict((c) => c.expression(sql`lower(email)`).doNothing())
        .returning(["id", "email", "name", "role"])
        .executeTakeFirst();
      if (!user) throw problems.emailTaken();
      return reply.code(201).send(user);
    },
  );

  app.post(
    "/auth/login",
    {
      // 5 attempts a minute per address and email, counted before the password is checked
      config: {
        rateLimit: {
          max: 5,
          timeWindow: "1 minute",
          hook: "preHandler",
          keyGenerator: (request) =>
            `${request.ip}:${(request.body as { email?: string }).email}`,
        },
      },
      schema: {
        body: Login,
        response: { 200: z.object({ token: z.string(), expires_in: z.number() }) },
      },
    },
    async (request) => {
      const { email, password } = request.body;
      const user = await db
        .selectFrom("users")
        .select(["id", "password_hash"])
        .where(sql`lower(email)`, "=", email)
        .executeTakeFirst();
      const ok = await verifyPassword(password, user?.password_hash ?? DUMMY);
      // the same answer for a wrong email and a wrong password
      if (!user || !ok) throw problems.badLogin();
      return { token: await startSession(user.id), expires_in: 30 * 24 * 3600 };
    },
  );

  app.post("/auth/logout", { onRequest: authenticate }, async (request, reply) => {
    await endSession(request.token ?? "");
    return reply.code(204).send();
  });

  // exercise 4: sign out on every device
  app.post(
    "/auth/logout-all",
    { onRequest: authenticate },
    async (request, reply) => {
      await db
        .deleteFrom("sessions")
        .where("user_id", "=", currentUser(request).id)
        .execute();
      return reply.code(204).send();
    },
  );

  app.get(
    "/me",
    { onRequest: authenticate, schema: { response: { 200: UserOut } } },
    async (request) => currentUser(request),
  );
};
