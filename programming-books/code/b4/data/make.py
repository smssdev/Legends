"""Writes the examples of Book 4, chapter "Data at Scale", in English and Arabic.
Run: python3 make.py   (after `npm ci` in code/b4; Docker; PostgreSQL through code/b3/bin/pg-start and Redis
through bin/redis-start)

Three ways to take load off one database, each run for real:
- a streaming replica of PostgreSQL 18, set to apply changes 3 seconds late so that its lag is visible:
  replica.ts shows a stale read, and "read your own writes" routing that avoids it;
- a cache-aside layer in Redis for the free slots, with the timings of a miss and a hit, and the cache
  cleared when a booking changes them;
- monthly range partitions on 2,000,000 bookings: the planner reads one partition for one month, and
  removing six months of old data is a DROP instead of a DELETE.
Transcripts are *.sh.
"""
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_pools="two pools: writes always go to the primary, reads usually to the replica",
        w_c_recent="read your own writes: for 5 seconds after a user writes, their reads go to the primary",
        w_c_poll="write on the primary, then ask the replica every half second",
        w_c_aside="cache-aside: look in the cache, else ask the database and remember the answer for 30 s",
        w_c_clear="a booking changes the free slots: delete the cached answer in the same step",
        w_c_parts="one partition per month; the parent table only routes rows to them",
        w_c_warm="open the connection first, so the timings below are of the queries alone",
        w_d_lag="replica lag", w_d_not="not on the replica yet", w_d_seen="on the replica after",
        w_d_owner="owner, just after booking, reads from", w_d_other="another user reads from",
        w_d_found="found", w_d_missing="not found",
        w_d_read="read", w_d_from="from", w_d_free="free slots", w_d_booked="booking made, cache cleared",
        w_s_lag="Write on the primary, read on the replica", w_s_cache="The free slots, with a cache in front",
        w_s_prune="One month, out of 24 partitions", w_s_delete="Removing six months: DELETE",
        w_s_drop="Removing six months: dropping partitions",
    ),
    "ar": dict(
        w_c_pools="مجمعان: الكتابة دائماً إلى الرئيسية، والقراءة غالباً من النسخة",
        w_c_recent="اقرأ ما كتبته: خمس ثوانٍ بعد كتابة المستخدم، تذهب قراءاته إلى الرئيسية",
        w_c_poll="اكتب في الرئيسية، ثم اسأل النسخة كل نصف ثانية",
        w_c_aside="الذاكرة جانباً: ابحث في الذاكرة المؤقتة، وإلا فاسأل قاعدة البيانات وتذكّر الإجابة 30 ثانية",
        w_c_clear="الحجز يغيّر المواعيد المتاحة: احذف الإجابة المخزنة في الخطوة نفسها",
        w_c_parts="قسم لكل شهر؛ والجدول الأب يوجّه الصفوف إليها فقط",
        w_c_warm="افتح الاتصال أولاً، فتكون الأزمنة أدناه للاستعلامات وحدها",
        w_d_lag="تأخر النسخة", w_d_not="ليس على النسخة بعد", w_d_seen="على النسخة بعد",
        w_d_owner="صاحب العمل، بعد الحجز مباشرة، يقرأ من", w_d_other="مستخدم آخر يقرأ من",
        w_d_found="موجود", w_d_missing="غير موجود",
        w_d_read="قراءة", w_d_from="من", w_d_free="مواعيد متاحة", w_d_booked="صُنع حجز، وحُذفت الذاكرة",
        w_s_lag="اكتب في الرئيسية، واقرأ من النسخة", w_s_cache="المواعيد المتاحة، وأمامها ذاكرة مؤقتة",
        w_s_prune="شهر واحد، من 24 قسماً", w_s_delete="حذف ستة أشهر: DELETE",
        w_s_drop="حذف ستة أشهر: إسقاط الأقسام",
    ),
}

FILES = {
    ".env": '''PRIMARY_URL=postgres://bit:secret@localhost:5433/shop
REPLICA_URL=postgres://bit:secret@localhost:5434/shop
REDIS_URL=redis://localhost:6379
''',
    "package.json": '{\n  "private": true,\n  "type": "module"\n}\n',
    "schema.sql": '''CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_id integer NOT NULL,
  starts_at timestamptz NOT NULL,
  email text NOT NULL
);
CREATE INDEX ON bookings (staff_id, starts_at);
''',
    "db.ts": '''import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

// {w_c_pools}
export const primary = new pg.Pool({ connectionString: process.env.PRIMARY_URL });
export const replica = new pg.Pool({ connectionString: process.env.REPLICA_URL });

const lastWrite = new Map<string, number>();

export async function write(user: string, sql: string, params: unknown[]) {
  const result = await primary.query(sql, params);
  lastWrite.set(user, Date.now());
  return result;
}

// {w_c_recent}
export function readerFor(user: string) {
  const at = lastWrite.get(user);
  return at !== undefined && Date.now() - at < 5000 ? primary : replica;
}
''',
    "replica.ts": '''import { setTimeout as sleep } from "node:timers/promises";
import { primary, readerFor, replica, write } from "./db.ts";

const find = "SELECT id FROM bookings WHERE email = $1";

// {w_c_poll}
const start = Date.now();
const { rows } = await write(
  "owner",
  "INSERT INTO bookings (staff_id, starts_at, email) VALUES (1, now(), $1) RETURNING id",
  ["sara@example.com"],
);
const owner = readerFor("owner");
const other = readerFor("someone-else");
const label = (pool: unknown) => (pool === primary ? "primary" : "replica");
const seen = async (pool: typeof primary) =>
  (await pool.query(find, ["sara@example.com"])).rowCount ? "{w_d_found}" : "{w_d_missing}";
console.log(`{w_d_owner} ${label(owner)}: ${await seen(owner)}`);
console.log(`{w_d_other} ${label(other)}: ${await seen(other)}`);

for (;;) {
  const found = await replica.query(find, ["sara@example.com"]);
  const ms = Math.round((Date.now() - start) / 500) * 500;
  if (found.rowCount) {
    console.log(`booking ${rows[0]!.id}: {w_d_seen} ~${ms} ms`);
    break;
  }
  console.log(`~${ms} ms: {w_d_not}`);
  await sleep(500);
}
await primary.end();
await replica.end();
''',
    "cache.ts": '''import { createClient } from "redis";
import { primary } from "./db.ts";

const redis = await createClient({ url: process.env.REDIS_URL }).connect();
const key = (staff: number, day: string) => `slots:${staff}:${day}`;

// {w_c_aside}
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

// {w_c_clear}
export async function book(staff: number, day: string, time: string, email: string) {
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
''',
    "cache-demo.ts": '''import { book, close, freeSlots } from "./cache.ts";
import { primary } from "./db.ts";

await primary.query("SELECT 1"); // {w_c_warm}

async function read() {
  const start = performance.now();
  const { from, slots } = await freeSlots(1, "2026-12-01");
  const ms = (performance.now() - start).toFixed(2);
  console.log(`{w_d_read} ${ms} ms  {w_d_from} ${from.padEnd(8)}  ${slots.length} {w_d_free}`);
}

await read();
await read();
await read();
await book(1, "2026-12-01", "10:30", "nour@example.com");
console.log("{w_d_booked}");
await read();
await read();
await close();
''',
    "partitions.sql": '''-- {w_c_parts}
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY,
  staff_id integer NOT NULL,
  starts_at timestamptz NOT NULL,
  email text NOT NULL
) PARTITION BY RANGE (starts_at);

DO $$
DECLARE month date;
BEGIN
  FOR month IN SELECT generate_series(date '2025-01-01', date '2026-12-01', interval '1 month') LOOP
    EXECUTE format(
      'CREATE TABLE %I PARTITION OF bookings FOR VALUES FROM (%L) TO (%L)',
      'bookings_' || to_char(month, 'YYYY_MM'), month, month + interval '1 month');
  END LOOP;
END $$;

INSERT INTO bookings (staff_id, starts_at, email)
SELECT i % 500 + 1, timestamptz '2025-01-01' + i * interval '30 seconds', 'c' || i || '@example.com'
  FROM generate_series(1, 2000000) i;
ANALYZE bookings;
''',
    "delete.sql": '''\\timing on
DELETE FROM bookings WHERE starts_at < '2025-07-01';
''',
    "drop.sql": '''\\timing on
DROP TABLE bookings_2025_07, bookings_2025_08, bookings_2025_09,
           bookings_2025_10, bookings_2025_11, bookings_2025_12;
''',
}


def sh(cmd, check=True):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True, check=check)


def start_replication():
    """PostgreSQL 18 primary on 5433, and a streaming replica on 5434 that applies changes 3 s late."""
    for name in ("b4-primary", "b4-replica"):
        sh(f"docker rm -f {name}", check=False)
    sh("docker run -d --name b4-primary --network host -e POSTGRES_USER=bit -e POSTGRES_PASSWORD=secret "
       "-e POSTGRES_DB=shop postgres:18 -c port=5433 -c listen_addresses=localhost -c wal_level=replica")
    for _ in range(60):
        if sh("docker exec b4-primary pg_isready -q -h localhost -p 5433", check=False).returncode == 0:
            break
        time.sleep(0.5)
    time.sleep(1)
    psql = "docker exec -e PGPASSWORD=secret b4-primary psql -h localhost -p 5433 -U bit -d shop -q -c"
    sh(f"{psql} \"CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'repl'\"")
    sh("docker exec b4-primary bash -c 'echo \"host replication replicator 127.0.0.1/32 scram-sha-256\" "
       ">> $PGDATA/pg_hba.conf'")
    sh(f"{psql} 'SELECT pg_reload_conf()'")
    sh("docker run -d --name b4-replica --network host --user postgres -e PGPASSWORD=repl --entrypoint bash "
       "postgres:18 -c \"pg_basebackup -h localhost -p 5433 -U replicator -D /tmp/data -R && "
       "chmod 700 /tmp/data && echo \\\"recovery_min_apply_delay = '3s'\\\" >> /tmp/data/postgresql.auto.conf && "
       "exec postgres -D /tmp/data -c port=5434 -c listen_addresses=localhost\"")
    for _ in range(60):
        if sh("docker exec b4-replica pg_isready -q -h localhost -p 5434", check=False).returncode == 0:
            return psql
        time.sleep(0.5)
    raise RuntimeError(sh("docker logs b4-replica", check=False).stdout)


def record(folder, t):
    psql = start_replication()
    schema = (folder / "schema.sql").read_text().replace("\n", " ")
    sh(f"{psql} \"{schema}\"")
    time.sleep(4)  # the replica receives the table
    subprocess.run(["redis-start", "--fresh"], env=CLEAN, check=True)
    env = dict(CLEAN, **dict(line.split("=", 1) for line in (folder / ".env").read_text().split()))
    s = Session(folder)
    s.note(t["w_s_lag"])
    s.run("node --env-file=.env replica.ts")
    s.save(folder / "replica.sh")
    s.note(t["w_s_cache"])
    s.run("node --env-file=.env cache-demo.ts")
    s.save(folder / "cache.sh")
    del env

    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s.run("psql shop -q -f partitions.sql")
    s.lines.clear()
    s.note(t["w_s_prune"])
    s.run("psql shop -At -c \"EXPLAIN (COSTS OFF) SELECT count(*) FROM bookings "
          "WHERE starts_at >= '2026-03-01' AND starts_at < '2026-04-01'\" | grep -v Filter")
    s.note(t["w_s_delete"])
    s.run("psql shop -f delete.sql | grep -E 'DELETE|Time' | sed -E 's/Time: ([0-9.]+) ms.*/Time: \\1 ms/'",
          shown="psql shop -f delete.sql")
    s.note(t["w_s_drop"])
    s.run("psql shop -f drop.sql | grep -E 'DROP|Time' | sed -E 's/Time: ([0-9.]+) ms.*/Time: \\1 ms/'",
          shown="psql shop -f drop.sql")
    s.run("psql shop -c 'SELECT count(*) FROM bookings'")
    s.save(folder / "partitions.sh")


try:
    for lang, t in T.items():
        if sys.argv[1:] and lang not in sys.argv[1:]:
            continue
        folder = HERE / lang
        if folder.exists():
            shutil.rmtree(folder)
        folder.mkdir(parents=True)
        for name, text in FILES.items():
            (folder / name).write_text(fill(text, t))
        os.symlink(B4 / "node_modules", folder / "node_modules")
        subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "84", "--write", "*.ts"],
                       cwd=folder, check=True, capture_output=True)
        record(folder, t)
        (folder / "node_modules").unlink()
        (folder / ".env").rename(folder / ".env.example")
        print("wrote", lang)
finally:
    for name in ("b4-primary", "b4-replica"):
        sh(f"docker rm -f {name}", check=False)
