import { createHmac, timingSafeEqual } from "node:crypto";
import { config } from "./config.ts";
import { pool } from "./db.ts";

const DEPOSIT = 5000; // piastres

export async function startDeposit(bookingId: number) {
  // الدفعة موجودة قبل أن يدفع الزبون: الـ webhook يكملها فقط
  const { rows } = await pool.query<{ id: number }>(
    `INSERT INTO payments (booking_id, amount)
     SELECT id, $2 FROM bookings WHERE id = $1 AND status = 'awaiting_deposit'
     RETURNING id`,
    [bookingId, DEPOSIT],
  );
  const payment = rows[0];
  if (!payment) return null;
  const res = await fetch(`${config.providerUrl}/checkouts`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${config.providerKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      amount: DEPOSIT,
      currency: "EGP",
      reference: String(payment.id),
    }),
  });
  if (!res.ok) throw new Error(`provider answered ${res.status}`);
  const checkout = (await res.json()) as { id: string; url: string };
  await pool.query("UPDATE payments SET checkout_id = $1 WHERE id = $2", [
    checkout.id,
    payment.id,
  ]);
  return checkout.url;
}

// التوقيع: HMAC-SHA256 للطابع الزمني والجسم، بالسر المشترك
export function verifySignature(header: string, body: string, now = Date.now()) {
  const parts = Object.fromEntries(
    header.split(",").map((p) => p.split("=") as [string, string]),
  );
  const t = Number(parts.t);
  // الطابع الزمني القديم إعادة لطلب مسجَّل
  if (!Number.isInteger(t) || Math.abs(now / 1000 - t) > 300) return false;
  const expected = createHmac("sha256", config.webhookSecret)
    .update(`${t}.${body}`)
    .digest();
  const given = Buffer.from(parts.v1 ?? "", "hex");
  return given.length === expected.length && timingSafeEqual(given, expected);
}

type Event = { id: string; type: string; data: { checkout_id: string } };

export async function applyEvent(
  event: Event,
): Promise<"applied" | "duplicate" | "ignored"> {
  const client = await pool.connect();
  try {
    // الكل أو لا شيء: الدفعة والحجز والبريد المطلوب إرساله
    await client.query("BEGIN");
    // المزوّدون يسلّمون مرة على الأقل: رقم الحدث يجعل التسليم الثاني بلا أثر
    const fresh = await client.query(
      "INSERT INTO webhook_events (id) VALUES ($1) ON CONFLICT DO NOTHING",
      [event.id],
    );
    if (fresh.rowCount === 0) {
      await client.query("ROLLBACK");
      return "duplicate";
    }
    if (event.type !== "checkout.paid") {
      await client.query("COMMIT");
      return "ignored";
    }
    const { rows } = await client.query<{
      booking_id: number;
      amount: number;
      email: string;
    }>(
      `UPDATE payments p SET status = 'paid'
         FROM bookings b
        WHERE p.checkout_id = $1 AND p.status = 'pending' AND b.id = p.booking_id
        RETURNING p.booking_id, p.amount, b.email`,
      [event.data.checkout_id],
    );
    const paid = rows[0];
    if (paid) {
      await client.query("UPDATE bookings SET status = 'confirmed' WHERE id = $1", [
        paid.booking_id,
      ]);
      // البريد: صف في هذه المعاملة، يرسله المرسِل بعد الاعتماد
      await client.query(
        "INSERT INTO outbox (recipient, subject, body) VALUES ($1, $2, $3)",
        [
          paid.email,
          "وصل عربونك",
          `تم الحجز: 1 ديسمبر، 10:00. العربون المدفوع: {amount} جنيهاً.`.replace(
            "{amount}",
            String(paid.amount / 100),
          ),
        ],
      );
    }
    await client.query("COMMIT");
    return "applied";
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}
