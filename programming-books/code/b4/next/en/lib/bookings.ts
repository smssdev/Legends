import "server-only";
import { pool } from "./db";

export type Slot = { starts_at: string; ends_at: string };
export type BookResult = { ok: true; id: number } | { ok: false; reason: "taken" };

// the free slots, computed by the database in the business's own time zone
export async function freeSlots(staffId: number, date: string): Promise<Slot[]> {
  const { rows } = await pool.query<{ starts_at: Date; ends_at: Date }>(
    `SELECT lower(slot) AS starts_at, upper(slot) AS ends_at
       FROM generate_series(($2::date + time '10:00') AT TIME ZONE 'Africa/Cairo',
                            ($2::date + time '13:30') AT TIME ZONE 'Africa/Cairo',
                            interval '30 minutes') AS t (start),
            tstzrange(start, start + interval '30 minutes') AS slot
      WHERE NOT EXISTS (SELECT 1 FROM bookings b
                         WHERE b.staff_id = $1 AND b.status = 'confirmed'
                           AND b.during && slot)
      ORDER BY 1`,
    [staffId, date],
  );
  return rows.map((r) => ({
    starts_at: r.starts_at.toISOString(),
    ends_at: r.ends_at.toISOString(),
  }));
}

export async function book(input: {
  staffId: number;
  startsAt: string;
  email: string;
}): Promise<BookResult> {
  try {
    const { rows } = await pool.query<{ id: number }>(
      `INSERT INTO bookings (staff_id, service_id, email, during)
       VALUES ($1, 1, $3,
               tstzrange($2::timestamptz, $2::timestamptz + interval '30 minutes'))
       RETURNING id`,
      [input.staffId, input.startsAt, input.email],
    );
    return { ok: true, id: rows[0]!.id };
  } catch (error) {
    // 23P01: an exclusion violation, the constraint of Chapter 1
    if ((error as { code?: string }).code === "23P01")
      return { ok: false, reason: "taken" };
    throw error;
  }
}

export async function staffList() {
  const { rows } = await pool.query<{ id: number; name: string }>(
    "SELECT id, name FROM staff ORDER BY id",
  );
  return rows;
}

export async function findBooking(id: number) {
  const { rows } = await pool.query<{
    id: number;
    staff: string;
    starts_at: Date;
    email: string;
  }>(
    `SELECT b.id, s.name AS staff, lower(b.during) AS starts_at, b.email
       FROM bookings b JOIN staff s ON s.id = b.staff_id WHERE b.id = $1`,
    [id],
  );
  return rows[0];
}
