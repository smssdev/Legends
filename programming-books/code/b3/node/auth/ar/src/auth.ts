import type { FastifyRequest } from "fastify";
import { problems } from "./problem.ts";
import { userForToken } from "./sessions.ts";

export type User = NonNullable<Awaited<ReturnType<typeof userForToken>>>;
export type Role = "customer" | "admin";

declare module "fastify" {
  interface FastifyRequest {
    user?: User;
    token?: string;
  }
}

// Authentication: who is calling? (Authorization: Bearer <token>)
export async function authenticate(request: FastifyRequest) {
  const [scheme, token] = (request.headers.authorization ?? "").split(" ");
  const user = scheme === "Bearer" && token ? await userForToken(token) : undefined;
  if (!user) throw problems.unauthenticated();
  request.user = user;
  request.token = token;
}

// التفويض: المستخدم معروف؛ فهل يجوز له هذا؟
export function requireRole(role: Role) {
  return async (request: FastifyRequest) => {
    if (request.user?.role !== role) throw problems.forbidden(role);
  };
}

export function currentUser(request: FastifyRequest): User {
  if (!request.user) throw problems.unauthenticated();
  return request.user;
}
