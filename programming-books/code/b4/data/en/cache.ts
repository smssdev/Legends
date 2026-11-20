import { createClient } from "redis";
import { primary } from "./db.ts";

const redis = await createClient({ url: process.env.REDIS_URL }).connect();
const key = (staff: number, day: string) => `slots:${staff}:${day}`;

// cache-aside: look in the cache, else ask the database and remember the answer for 30 s
export async function freeSlots(staff: number, day: string) {
  const cached = await redis.get(key(staff, day));
  if (cached) return { from: "cache", slots: JSON.parse(cached) as string[] };
  const { rows } = await primary.query<{ slot: string }>(
    `SELECT to_char(t, 'HH24:MI') AS slot
       FROM generate_series($2::date + time '10:00', $2::date + time '13:30', interval '30 min') t
      WHERE NOT EXISTS (SELECT 1 FROM bookings
                         WHERE staff_id = $1 AND starts_at = t AT TIME ZONE 'Africa/Cairo')
      ORDER BY t`,
    [staff, day],
  );
  const slots = rows.map((r) => r.slot);
  await redis.set(key(staff, day), JSON.stringify(slots), { EX: 30 });
  return { from: "database", slots };
}

// a booking changes the free slots: delete the cached answer in the same step
export async function book(
  staff: number,
  day: string,
  time: string,
  email: string,
) {
  await primary.query(
    `INSERT INTO bookings (staff_id, starts_at, email)
     VALUES ($1, ($2::date + $3::time) AT TIME ZONE 'Africa/Cairo', $4)`,
    [staff, day, time, email],
  );
  await redis.del(key(staff, day));
}

export const close = async () => {
  await redis.quit();
  await primary.end();
};
