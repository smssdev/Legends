import { setTimeout as sleep } from "node:timers/promises";
import { sql } from "kysely";
import { connect } from "./db.ts";

const db = connect();
let running = true;
process.once("SIGTERM", () => (running = false));

// the worker: send what the outbox holds, mark it sent, repeat
while (running) {
  const sent = await db.transaction().execute(async (trx) => {
    const rows = await trx
      .selectFrom("outbox")
      .select(["id", "payload"])
      .where("sent_at", "is", null)
      .orderBy("id")
      .limit(10)
      // SKIP LOCKED: two workers never take the same row
      .forUpdate()
      .skipLocked()
      .execute();
    for (const row of rows) {
      const { order_id } = row.payload as { order_id: number };
      const { email } = await trx
        .selectFrom("orders")
        .innerJoin("users", "users.id", "orders.user_id")
        .select("users.email")
        .where("orders.id", "=", order_id)
        .executeTakeFirstOrThrow();
      console.log(JSON.stringify({ msg: "email sent", to: email, order_id }));
      await trx
        .updateTable("outbox")
        .set({ sent_at: sql`now()` })
        .where("id", "=", row.id)
        .execute();
    }
    return rows.length;
  });
  if (sent === 0) await sleep(500);
}
await db.destroy();
