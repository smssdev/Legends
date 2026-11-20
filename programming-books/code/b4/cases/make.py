"""Writes the examples of Book 4, chapter "Six System Design Case Studies", in English and Arabic.
Run: python3 make.py   (after `npm ci` in code/b4; PostgreSQL and Redis through code/b3/bin)

The heart of each case, run for real:
- shortlinks: base62.ts turns sequence numbers into short codes and back;
- rate limiter: ratelimit.ts, a sliding-window limit kept in Redis by one atomic Lua script;
- reminders: delayed.ts, jobs due at a time, in a Redis sorted set, claimed atomically by a worker;
- feed: fanout.ts compares the work of fan-out on write and on read, for ordinary and very popular accounts;
- chat: sequence.sql gives each message its number within its conversation, so clients can order and resume;
- autocomplete: autocomplete.sql searches 500,000 business names by prefix with the right index.
Transcripts are *.sh.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_alphabet="62 characters that are safe in any URL",
        w_c_lua="one script, run atomically by Redis: no other client can act between its steps",
        w_c_window="drop the requests older than the window, count the rest, and add this one if allowed",
        w_c_due="the score is the time the job is due: the set is always sorted by it",
        w_c_claim="take one due job and remove it in one atomic step: two workers never get the same job",
        w_c_seq="each conversation counts its own messages: no gaps, no reordering, easy to resume",
        w_c_pattern="text_pattern_ops makes LIKE 'prefix%' use the index",
        w_c_key="the name in lower case, ordered byte by byte (C): one index serves the prefix and the order",
        w_t_request="request", w_t_allowed="allowed", w_t_refused="refused",
        w_t_strategy="strategy", w_t_post="writes per post", w_t_read="reads per feed view",
        w_t_ordinary="ordinary account (300 followers)", w_t_star="popular account (2,000,000 followers)",
        w_t_write="fan-out on write", w_t_onread="fan-out on read",
        w_d_scheduled="scheduled", w_d_due="due now", w_d_ran="ran", w_d_left="still waiting",
        w_s_codes="Sequence numbers as short codes", w_s_limit="5 requests a second for one client, 8 tries",
        w_s_delayed="Reminders due at different times", w_s_fanout="The cost of a feed",
        w_s_seq="Messages numbered per conversation", w_s_auto="Names starting with “bit h”, among 500,000",
    ),
    "ar": dict(
        w_c_alphabet="62 حرفاً آمنة في أي عنوان URL",
        w_c_lua="سكربت واحد، يشغّله Redis ذرياً: لا يستطيع عميل آخر أن يفعل شيئاً بين خطواته",
        w_c_window="احذف الطلبات الأقدم من النافذة، وعدّ الباقي، وأضف هذا إن كان مسموحاً",
        w_c_due="الدرجة هي وقت استحقاق المهمة: المجموعة مرتبة به دائماً",
        w_c_claim="خذ مهمة مستحقة واحدة واحذفها في خطوة ذرية واحدة: لا يأخذ عاملان المهمة نفسها أبداً",
        w_c_seq="كل محادثة تعدّ رسائلها: بلا فجوات ولا إعادة ترتيب، ومتابعة سهلة",
        w_c_pattern="text_pattern_ops يجعل LIKE 'prefix%' يستعمل الفهرس",
        w_c_key="الاسم بأحرف صغيرة، مرتباً بايتاً بايتاً (C): فهرس واحد يخدم البادئة والترتيب",
        w_t_request="الطلب", w_t_allowed="مسموح", w_t_refused="مرفوض",
        w_t_strategy="الإستراتيجية", w_t_post="كتابات لكل منشور", w_t_read="قراءات لكل عرض للخلاصة",
        w_t_ordinary="حساب عادي (300 متابع)", w_t_star="حساب مشهور (2,000,000 متابع)",
        w_t_write="التوزيع عند الكتابة", w_t_onread="التوزيع عند القراءة",
        w_d_scheduled="جُدولت", w_d_due="مستحقة الآن", w_d_ran="نُفذت", w_d_left="ما زالت تنتظر",
        w_s_codes="أرقام متسلسلة رموزاً قصيرة", w_s_limit="5 طلبات في الثانية لعميل واحد، 8 محاولات",
        w_s_delayed="تذكيرات مستحقة في أوقات مختلفة", w_s_fanout="كلفة الخلاصة",
        w_s_seq="رسائل مرقّمة لكل محادثة", w_s_auto="الأسماء التي تبدأ بـ «bit h»، بين 500,000",
    ),
}

FILES = {
    ".env": "REDIS_URL=redis://localhost:6379\n",
    "package.json": '{\n  "private": true,\n  "type": "module"\n}\n',
    "base62.ts": '''// {w_c_alphabet}
const ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

export function encode(n: bigint): string {
  let code = "";
  do {
    code = ALPHABET[Number(n % 62n)] + code;
    n /= 62n;
  } while (n > 0n);
  return code;
}

export function decode(code: string): bigint {
  let n = 0n;
  for (const char of code) n = n * 62n + BigInt(ALPHABET.indexOf(char));
  return n;
}

for (const id of [1n, 61n, 62n, 3_843n, 1_000_000n, 56_800_235_583n]) {
  const code = encode(id);
  console.log(String(id).padStart(12), "→", code.padEnd(7), "→", String(decode(code)));
}
''',
    "ratelimit.ts": '''import { setTimeout as sleep } from "node:timers/promises";
import { createClient } from "redis";

const redis = await createClient({ url: process.env.REDIS_URL }).connect();

// {w_c_lua}
const SLIDING = `
  local key, now, window, limit = KEYS[1], tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3])
  -- {w_c_window}
  redis.call("ZREMRANGEBYSCORE", key, 0, now - window)
  if redis.call("ZCARD", key) >= limit then return 0 end
  redis.call("ZADD", key, now, ARGV[4])
  redis.call("PEXPIRE", key, window)
  return 1
`;

export async function allow(client: string, limit = 5, windowMs = 1000) {
  const now = Date.now();
  const id = `${now}-${Math.random()}`;
  const ok = await redis.eval(SLIDING, {
    keys: [`rate:${client}`],
    arguments: [String(now), String(windowMs), String(limit), id],
  });
  return ok === 1;
}

console.log("{w_t_request}", "  ms ", " ");
const start = Date.now();
for (let i = 1; i <= 8; i++) {
  if (i === 7) await sleep(1000);
  const ok = await allow("203.0.113.7");
  const at = String(Math.round((Date.now() - start) / 100) * 100).padStart(5);
  console.log(String(i).padStart(7), at, ok ? "{w_t_allowed}" : "{w_t_refused}");
}
await redis.quit();
''',
    "delayed.ts": '''import { createClient } from "redis";

const redis = await createClient({ url: process.env.REDIS_URL }).connect();
const now = Date.parse("2026-11-30T10:00:00Z");

// {w_c_due}
const jobs = [
  ["remind booking 41", now - 60_000],
  ["remind booking 42", now],
  ["remind booking 43", now + 3_600_000],
];
for (const [job, at] of jobs) await redis.zAdd("reminders", { score: at as number, value: job as string });
console.log("{w_d_scheduled}:", await redis.zCard("reminders"));

// {w_c_claim}
const CLAIM = `
  local due = redis.call("ZRANGEBYSCORE", KEYS[1], "-inf", ARGV[1], "LIMIT", 0, 1)
  if #due == 0 then return false end
  redis.call("ZREM", KEYS[1], due[1])
  return due[1]
`;
for (;;) {
  const job = await redis.eval(CLAIM, { keys: ["reminders"], arguments: [String(now)] });
  if (!job) break;
  console.log("{w_d_ran}:", job);
}
console.log("{w_d_left}:", await redis.zRange("reminders", 0, -1));
await redis.quit();
''',
    "fanout.ts": '''// one post, and one view of a follower's feed showing posts from 200 accounts they follow
const cases = [
  ["{w_t_ordinary}", 300],
  ["{w_t_star}", 2_000_000],
] as const;
const followed = 200;

console.log("{w_t_strategy}".padEnd(20), "{w_t_post}".padStart(20), "{w_t_read}".padStart(22));
for (const [account, followers] of cases) {
  console.log(account);
  console.log("  {w_t_write}".padEnd(20), followers.toLocaleString("en").padStart(20), "1".padStart(22));
  console.log("  {w_t_onread}".padEnd(20), "1".padStart(20), String(followed).padStart(22));
}
''',
    "sequence.sql": '''CREATE TABLE conversations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  last_seq integer NOT NULL DEFAULT 0
);
CREATE TABLE messages (
  conversation_id bigint NOT NULL REFERENCES conversations (id),
  seq integer NOT NULL,
  body text NOT NULL,
  sent_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (conversation_id, seq)
);

-- {w_c_seq}
CREATE FUNCTION send(conversation bigint, text text) RETURNS integer AS $$
  WITH next AS (
    UPDATE conversations SET last_seq = last_seq + 1 WHERE id = conversation RETURNING last_seq
  )
  INSERT INTO messages (conversation_id, seq, body)
  SELECT conversation, last_seq, text FROM next
  RETURNING seq;
$$ LANGUAGE sql;
''',
    "autocomplete.sql": '''CREATE TABLE businesses (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  -- {w_c_key}
  search_key text COLLATE "C" GENERATED ALWAYS AS (lower(name)) STORED
);
INSERT INTO businesses (name)
SELECT (ARRAY['Bit', 'Nour', 'Sara', 'Cairo', 'Nile', 'Delta', 'Star', 'Green'])[1 + i % 8] || ' '
    || (ARRAY['Hair', 'Clinic', 'Studio', 'Dental', 'Spa', 'Tutors', 'Garage', 'Barber'])[1 + (i / 8) % 8]
    || ' ' || i
  FROM generate_series(1, 500000) i;
-- {w_c_pattern}
CREATE INDEX businesses_name_prefix ON businesses (lower(name) text_pattern_ops);
CREATE INDEX businesses_search_key ON businesses (search_key);
ANALYZE businesses;
''',
}


def record(folder, t):
    s = Session(folder)
    s.note(t["w_s_codes"])
    s.run("node base62.ts")
    s.save(folder / "base62.sh")
    subprocess.run(["redis-start", "--fresh"], env=CLEAN, check=True)
    s.note(t["w_s_limit"])
    s.run("node --env-file=.env ratelimit.ts")
    s.save(folder / "ratelimit.sh")
    s.note(t["w_s_delayed"])
    s.run("node --env-file=.env delayed.ts")
    s.save(folder / "delayed.sh")
    s.note(t["w_s_fanout"])
    s.run("node fanout.ts")
    s.save(folder / "fanout.sh")
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s.run("psql shop -q -f sequence.sql && psql shop -q -f autocomplete.sql")
    s.lines.clear()
    s.note(t["w_s_seq"])
    s.run("psql shop -q -c 'INSERT INTO conversations DEFAULT VALUES; INSERT INTO conversations DEFAULT VALUES'")
    s.run("psql shop -At -c \"SELECT send(1, 'Hi, is 10:30 free?'), send(2, 'Hello'), "
          "send(1, 'Yes, booked for you'), send(1, 'Thanks!')\"")
    s.run("psql shop -c 'SELECT conversation_id, seq, body FROM messages ORDER BY conversation_id, seq'")
    s.save(folder / "sequence.sh")
    s.note(t["w_s_auto"])
    for query in ("SELECT name FROM businesses WHERE lower(name) LIKE 'bit h%' ORDER BY lower(name) LIMIT 5",
                  "SELECT name FROM businesses WHERE search_key LIKE 'bit h%' ORDER BY search_key LIMIT 5"):
        s.run(f"psql shop -At -c \"{query}\" | head -2")
        s.run(f"psql shop -At -c \"EXPLAIN (ANALYZE, COSTS OFF) {query}\" "
              "| grep -E '^ *(->|Limit|Execution)' | sed -E 's/ \\(actual[^)]*\\)//; s/ +$//'",
              shown=f"psql shop -At -c \"EXPLAIN (ANALYZE, COSTS OFF) {query}\" | grep -E '^ *(->|Limit|Exec)'")
    s.save(folder / "autocomplete.sh")


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
