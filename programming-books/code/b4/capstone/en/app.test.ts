import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import pg from "pg";
import { apply } from "./billing.ts";
import { book, list } from "./bookings.ts";
import { pool, withSalon } from "./db.ts";

// the tests prepare data as the owner, and check it as the app
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

test("a salon never sees another salon's bookings", async () => {
  await book(a, {
    staff: "Mona",
    email: "x@example.com",
    start: at(10, 10),
    minutes: 30,
  });
  const seen = await list(b);
  assert.equal(seen.length, 0);
});

test("without a salon, a query returns nothing", async () => {
  const { rows } = await pool.query(
    "SELECT count(*)::int AS n FROM bookings",
  );
  assert.equal(rows[0].n, 0);
});

test("the plan limit holds under concurrent bookings", async () => {
  await owner.query(
    `INSERT INTO bookings (salon_id, staff, email, during)
     SELECT $1, 'Sara', 'old@example.com',
            tstzrange(t, t + interval '1 min')
     FROM generate_series(now(), now() + interval '2 days',
                          interval '1 day') AS t`,
    [b],
  );
  // ten at once, two left in the plan: exactly two may succeed
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

test("a webhook delivered twice is applied once", async () => {
  const event = {
    id: `evt_${a}`,
    type: "subscription.updated",
    salon: a,
    plan: "pro",
  };
  assert.deepEqual(await apply(event), { applied: true });
  assert.deepEqual(await apply(event), { applied: false });
});
