import { db } from "./db.ts";
import { hashPassword } from "./password.ts";

// Two customers with orders, and an admin. Real passwords are never written in code;
// these exist only on a developer's machine.
const people = [
  {
    email: "sara@example.com",
    name: "سارة",
    role: "customer",
    totals: [45000, 6000],
  },
  { email: "omar@example.com", name: "عمر", role: "customer", totals: [12000] },
  { email: "admin@example.com", name: "المدير", role: "admin", totals: [] },
];
for (const p of people) {
  const password_hash = await hashPassword(
    `${p.email.split("@")[0]}-password-2026`,
  );
  const { id } = await db
    .insertInto("users")
    .values({ email: p.email, name: p.name, role: p.role, password_hash })
    .returning("id")
    .executeTakeFirstOrThrow();
  for (const total of p.totals) {
    await db.insertInto("orders").values({ user_id: id, total }).execute();
  }
}
await db.destroy();
