import { createHash, randomBytes } from "node:crypto";
import type { FastifyRequest } from "fastify";
import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { sql } from "kysely";
import { z } from "zod";
import type { Deps } from "./app.ts";
import { hashPassword, verifyPassword } from "./password.ts";
import { problems } from "./problem.ts";

declare module "fastify" {
  interface FastifyRequest {
    userId?: number;
  }
}

const digest = (token: string) => createHash("sha256").update(token).digest("hex");
const Email = z.email().max(254).toLowerCase();
const DUMMY = await hashPassword("not anyone's password");

// who is calling? (Authorization: Bearer <token>)
export const authenticate = ({ db }: Deps) =>
  async function (request: FastifyRequest) {
    const [scheme, token] = (request.headers.authorization ?? "").split(" ");
    if (scheme !== "Bearer" || !token) throw problems.unauthenticated();
    const session = await db
      .selectFrom("sessions")
      .select("user_id")
      .where("token_hash", "=", digest(token))
      .where("expires_at", ">", sql<Date>`now()`)
      .executeTakeFirst();
    if (!session) throw problems.unauthenticated();
    request.userId = session.user_id;
  };

export const authRoutes =
  ({ db }: Deps): FastifyPluginAsyncZod =>
  async (app) => {
    app.post(
      "/auth/register",
      {
        schema: {
          body: z.strictObject({
            email: Email,
            password: z.string().min(12).max(128),
          }),
        },
      },
      async (request, reply) => {
        const { email, password } = request.body;
        const user = await db
          .insertInto("users")
          .values({ email, password_hash: await hashPassword(password) })
          .onConflict((c) => c.column("email").doNothing())
          .returning(["id", "email"])
          .executeTakeFirst();
        if (!user) throw problems.emailTaken();
        return reply.code(201).send(user);
      },
    );

    app.post(
      "/auth/login",
      {
        // 5 tries a minute per address and email, counted in Redis: every copy of the app shares the count
        config: {
          rateLimit: {
            max: 5,
            timeWindow: "1 minute",
            hook: "preHandler",
            keyGenerator: (request) =>
              `login:${request.ip}:${(request.body as { email?: string }).email}`,
          },
        },
        schema: {
          body: z.strictObject({ email: Email, password: z.string().max(128) }),
        },
      },
      async (request) => {
        const { email, password } = request.body;
        const user = await db
          .selectFrom("users")
          .select(["id", "password_hash"])
          .where("email", "=", email)
          .executeTakeFirst();
        // an unknown email still costs one hash, so timing does not reveal which emails exist
        const ok = await verifyPassword(password, user?.password_hash ?? DUMMY);
        if (!user || !ok) throw problems.badLogin();
        const token = randomBytes(32).toString("base64url");
        // only the token's hash is stored: a leaked table opens no account
        await db
          .insertInto("sessions")
          .values({
            token_hash: digest(token),
            user_id: user.id,
            expires_at: sql`now() + interval '30 days'`,
          })
          .execute();
        return { token };
      },
    );
  };
