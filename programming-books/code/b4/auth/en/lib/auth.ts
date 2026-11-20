import "server-only";
import { createHash, randomBytes } from "node:crypto";
import { cookies } from "next/headers";
import { pool } from "./db";
import { hashPassword, verifyPassword } from "./password";

export type User = {
  id: number;
  email: string;
  role: "owner" | "staff";
  business_id: number;
};

export class AuthError extends Error {
  status: 401 | 403;
  constructor(status: 401 | 403) {
    super(status === 401 ? "unauthenticated" : "forbidden");
    this.status = status;
  }
}

const COOKIE = "session";
const WEEK = 7 * 24 * 3600;
const digest = (token: string) => createHash("sha256").update(token).digest("hex");
let dummy: Promise<string> | undefined;

export async function signIn(
  email: string,
  password: string,
): Promise<string | null> {
  const { rows } = await pool.query<{ id: number; password_hash: string }>(
    "SELECT id, password_hash FROM users WHERE email = lower($1)",
    [email],
  );
  const user = rows[0];
  // an unknown email still costs one hash, so timing reveals nothing
  const ok = await verifyPassword(
    password,
    user?.password_hash ?? (await (dummy ??= hashPassword("x"))),
  );
  if (!user || !ok) return null;
  const token = randomBytes(32).toString("base64url");
  // only the hash of a token is stored: a stolen table opens no account
  await pool.query(
    "INSERT INTO sessions (token_hash, user_id, expires_at) VALUES ($1, $2, now() + $3 * interval '1 second')",
    [digest(token), user.id, WEEK],
  );
  return token;
}

export async function startWebSession(token: string) {
  (await cookies()).set(COOKIE, token, {
    // httpOnly: no script can read it; sameSite lax: other sites cannot send it with a form
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: WEEK,
  });
}

// who is calling: a bearer token (API) or the session cookie (web)
export async function currentUser(request?: Request): Promise<User | null> {
  const bearer = request?.headers
    .get("authorization")
    ?.match(/^Bearer (\S+)$/)?.[1];
  const token = bearer ?? (await cookies()).get(COOKIE)?.value;
  if (!token) return null;
  const { rows } = await pool.query<User>(
    `SELECT u.id, u.email, u.role, u.business_id
       FROM sessions s JOIN users u ON u.id = s.user_id
      WHERE s.token_hash = $1 AND s.expires_at > now()`,
    [digest(token)],
  );
  return rows[0] ?? null;
}

// the one check every door calls: 401 for nobody, 403 for the wrong role
export async function requireUser(
  roles: User["role"][],
  request?: Request,
): Promise<User> {
  const user = await currentUser(request);
  if (!user) throw new AuthError(401);
  if (!roles.includes(user.role)) throw new AuthError(403);
  return user;
}
