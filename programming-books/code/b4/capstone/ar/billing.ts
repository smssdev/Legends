import { createHmac, timingSafeEqual } from "node:crypto";
import { withSalon } from "./db.ts";
import { Problem } from "./bookings.ts";

const secret = process.env.BILLING_SECRET ?? "whsec_test";

// يوقّع المزوّد الجسم نفسه بالسر المشترك بيننا
export function verify(body: string, header: string | undefined) {
  const expected = createHmac("sha256", secret)
    .update(body)
    .digest("hex");
  const given = String(header ?? "").replace("sha256=", "");
  // قارن في زمن ثابت، فلا يكشف توقيت الإجابة شيئاً
  const ok =
    given.length === expected.length &&
    timingSafeEqual(Buffer.from(given), Buffer.from(expected));
  if (!ok) throw new Problem(401, "توقيع غير صالح");
}

type BillingEvent = {
  id: string;
  type: string;
  salon: number;
  plan: string;
};

export function apply(event: BillingEvent) {
  return withSalon(event.salon, async (db) => {
    // الحدث المعاد لا يُدخل شيئاً ولا يغيّر شيئاً
    const fresh = await db.query(
      `INSERT INTO billing_events (id) VALUES ($1)
       ON CONFLICT DO NOTHING`,
      [event.id],
    );
    if (fresh.rowCount === 0) return { applied: false };
    if (event.type === "subscription.updated") {
      const change = "UPDATE salons SET plan = $1 WHERE id = $2";
      await db.query(change, [event.plan, event.salon]);
    }
    return { applied: true };
  });
}
