import { withSalon } from "./db.ts";

export class Problem extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

type NewBooking = {
  staff: string;
  email: string;
  start: string;
  minutes: number;
};

export function book(salonId: number, b: NewBooking) {
  return withSalon(salonId, async (db) => {
    // اقفل صف الصالون: تتناوب حجوزاته المتزامنة هنا
    const { rows } = await db.query(
      `SELECT p.monthly_bookings AS max FROM salons s
       JOIN plans p ON p.id = s.plan WHERE s.id = $1 FOR UPDATE OF s`,
      [salonId],
    );
    // عُدّ حجوزات هذا الشهر تحت القفل، ثم قرّر
    const max: number | null = rows[0].max;
    if (max !== null) {
      const used = await db.query(
        `SELECT count(*)::int AS n FROM bookings
         WHERE created_at >= date_trunc('month', now())`,
      );
      if (used.rows[0].n >= max)
        throw new Problem(
          402,
          "المجاني: 5 حجوزات في الشهر. رقِّ إلى Pro للمزيد.",
        );
    }
    const end = new Date(Date.parse(b.start) + b.minutes * 60_000);
    try {
      const inserted = await db.query(
        `INSERT INTO bookings (salon_id, staff, email, during)
         VALUES ($1, $2, $3, tstzrange($4, $5)) RETURNING id`,
        [salonId, b.staff, b.email, b.start, end],
      );
      return { id: inserted.rows[0].id as string };
    } catch (error) {
      // 23P01: قيد الاستبعاد؛ الموعد حُجز للتو
      if ((error as { code?: string }).code === "23P01")
        throw new Problem(
          409,
          "حُجز هذا الموعد للتو. اختر موعداً آخر من فضلك.",
        );
      throw error;
    }
  });
}

export function list(salonId: number) {
  return withSalon(salonId, async (db) => {
    const { rows } = await db.query(
      "SELECT id, staff, email FROM bookings ORDER BY id",
    );
    return rows;
  });
}

export function one(salonId: number, id: string) {
  return withSalon(salonId, async (db) => {
    const { rows } = await db.query(
      "SELECT id, staff, email FROM bookings WHERE id = $1",
      [id],
    );
    if (!rows[0]) throw new Problem(404, "غير موجود");
    return rows[0];
  });
}
