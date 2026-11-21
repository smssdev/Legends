import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import pg from "pg";
import { apply } from "./billing.ts";
import { book, list } from "./bookings.ts";
import { pool, withSalon } from "./db.ts";

// تجهّز الاختبارات البيانات بصفة المالك، وتفحصها بصفة التطبيق
const owner = new pg.Pool({
  connectionString: "postgres://bit:secret@localhost:5432/shop",
});
let a = 0;
let b = 0;
before(async () => {
  const add = "INSERT INTO salons (name) VALUES ($1) RETURNING id";
  a = Number((await owner.query(add, ["Test A"])).rows[0].id);
  b = Number((await owner.query(add, ["Test B"])).rows[0].id);
});
after(() => Promise.all([owner.end(), pool.end()]));

const at = (day: number, hour: number) =>
  `2027-01-${day}T${hour}:00:00Z`;

test("لا يرى صالون حجوزات صالون آخر أبداً", async () => {
  await book(a, {
    staff: "Mona",
    email: "x@example.com",
    start: at(10, 10),
    minutes: 30,
  });
  const seen = await list(b);
  assert.equal(seen.length, 0);
});

test("بلا صالون، لا يعيد الاستعلام شيئاً", async () => {
  const { rows } = await pool.query(
    "SELECT count(*)::int AS n FROM bookings",
  );
  assert.equal(rows[0].n, 0);
});

test("حد الاشتراك يصمد أمام الحجوزات المتزامنة", async () => {
  await owner.query(
    `INSERT INTO bookings (salon_id, staff, email, during)
     SELECT $1, 'Sara', 'old@example.com',
            tstzrange(t, t + interval '1 min')
     FROM generate_series(now(), now() + interval '2 days',
                          interval '1 day') AS t`,
    [b],
  );
  // عشرة معاً، وبقي في الاشتراك اثنان: ينجح اثنان بالضبط
  const results = await Promise.allSettled(
    Array.from({ length: 10 }, (_, i) =>
      book(b, {
        staff: "Sara",
        email: `r${i}@example.com`,
        start: at(11, 10 + i),
        minutes: 30,
      }),
    ),
  );
  assert.equal(
    results.filter((r) => r.status === "fulfilled").length,
    2,
  );
  const used = await withSalon(b, (db) =>
    db.query("SELECT count(*)::int AS n FROM bookings"),
  );
  assert.equal(used.rows[0].n, 5);
});

test("الـwebhook المسلَّم مرتين يُطبَّق مرة", async () => {
  const event = {
    id: `evt_${a}`,
    type: "subscription.updated",
    salon: a,
    plan: "pro",
  };
  assert.deepEqual(await apply(event), { applied: true });
  assert.deepEqual(await apply(event), { applied: false });
});
