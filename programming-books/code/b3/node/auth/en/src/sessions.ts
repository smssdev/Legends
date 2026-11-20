import { createHash, randomBytes } from "node:crypto";
import { sql } from "kysely";
import { db } from "./db.ts";

const digest = (token: string) => createHash("sha256").update(token).digest("hex");

export async function startSession(userId: number) {
  // 32 random bytes: impossible to guess, and meaningless without the database
  const token = randomBytes(32).toString("base64url");
  await db
    .insertInto("sessions")
    // only the hash is stored: a leaked sessions table opens no account
    .values({
      token_hash: digest(token),
      user_id: userId,
      expires_at: sql`now() + interval '30 days'`,
    })
    .execute();
  return token;
}

export async function userForToken(token: string) {
  return db
    .selectFrom("sessions")
    .innerJoin("users", "users.id", "sessions.user_id")
    .select(["users.id", "users.email", "users.name", "users.role"])
    .where("sessions.token_hash", "=", digest(token))
    .where("sessions.expires_at", ">", sql<Date>`now()`)
    .executeTakeFirst();
}

export async function endSession(token: string) {
  await db.deleteFrom("sessions").where("token_hash", "=", digest(token)).execute();
}
