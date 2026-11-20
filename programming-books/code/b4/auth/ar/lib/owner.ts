import "server-only";
import { pool } from "./db";
import type { User } from "./auth";

export type OwnerBooking = {
  id: number;
  staff: string;
  starts_at: string;
  email: string;
  status: string;
};

// محصور في عمل المستخدم: شرط WHERE هو الصلاحية
export async function bookingsFor(user: User): Promise<OwnerBooking[]> {
  const { rows } = await pool.query<OwnerBooking & { starts_at: Date }>(
    `SELECT b.id, st.name AS staff, lower(b.during) AS starts_at, b.email, b.status
       FROM bookings b JOIN staff st ON st.id = b.staff_id
      WHERE st.business_id = $1
      ORDER BY lower(b.during)`,
    [user.business_id],
  );
  return rows.map((r) => ({ ...r, starts_at: r.starts_at.toISOString() }));
}

// حجز عمل آخر لا يطابق أي صف: هو «غير موجود» لا «ممنوع»
export async function cancelBooking(user: User, id: number): Promise<boolean> {
  const { rowCount } = await pool.query(
    `UPDATE bookings b SET status = 'cancelled'
       FROM staff st
      WHERE b.id = $2 AND st.id = b.staff_id AND st.business_id = $1 AND b.status = 'confirmed'`,
    [user.business_id, id],
  );
  return rowCount === 1;
}
