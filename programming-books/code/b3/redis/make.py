"""Writes the examples of Book 3, the shared chapter "Redis: Caching, Rate Limits and Locks".
Run: python3 make.py   (Redis through code/b3/bin/redis-start, PostgreSQL through pg-start; PHP through bin/php)

First redis-cli on its own: strings, counters, expiry, hashes and sorted sets. Then three programs, one per
edition each (node/*.ts with node-redis and pg, php/*.php with Predis and PDO): a cache in front of a slow
query, with invalidation; a stampede of twenty requests on a cold cache, without and with a lock; and a rate
limit that two servers share. What the terminal showed is saved as transcripts (*.sh).
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent
sys.path.insert(0, str(B3))
from rec import CLEAN, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_kit="Robot kit", w_wheels="Spare wheels", w_sara="sara", w_omar="omar", w_lina="lina",
        w_c_slow="the slow query: pg_sleep stands for a heavy report or a join over big tables",
        w_c_count="count the database queries in Redis, so every process adds to one number",
        w_c_aside="cache-aside: look in Redis first; on a miss, ask the database and keep the answer",
        w_c_ttl="forgotten after 60 seconds, even if nobody deletes it",
        w_c_change="changing the data: update the database first, then delete the cached copy",
        w_c_lock="only the request that gets the lock asks the database; the others wait and look again",
        w_c_token="a random token: only the owner of the lock may release it",
        w_c_release="delete the lock only if it is still ours, in one step on the server",
        w_c_window="one counter per client; the first request starts a 10-second window",
        w_c_multi="MULTI/EXEC: both commands run together, nothing in between",
        w_c_servers="two servers, two connections, one Redis: the limit is shared",
        w_c_fork="twenty processes, each with its own connections, like twenty PHP workers",
        w_d_first="first request", w_d_second="second request", w_d_third="third request",
        w_d_after="after the change", w_d_from="from", w_d_in="in",
        w_d_changed="price changed to 47000, cached copy deleted", w_d_left="seconds left in Redis:",
        w_d_requests="requests", w_d_queries="database queries",
        w_d_request="request", w_d_via="via server", w_d_allowed="allowed", w_d_of="of",
        w_d_refused="refused, 429, try again in", w_d_refused_short="refused, 429", w_d_seconds="s",
        w_s_strings="Strings, counters and expiry",
        w_s_types="Hashes and sorted sets",
        w_s_cache="A cache in front of a slow query",
        w_s_stampede="Twenty requests on a cold cache",
        w_s_rate="Five requests per 10 seconds, shared by two servers",
        w_c_sliding="exercise 5: a sliding window, one sorted-set member per request, scored by its time",
        w_d_wait="(2 seconds later)",
    ),
    "ar": dict(
        w_kit="عدة الروبوت", w_wheels="عجلات احتياطية", w_sara="sara", w_omar="omar", w_lina="lina",
        w_c_slow="الاستعلام البطيء: pg_sleep تمثل تقريراً ثقيلاً أو ربطاً بين جداول كبيرة",
        w_c_count="عُدّ استعلامات قاعدة البيانات في Redis، فتضيف كل عملية إلى رقم واحد",
        w_c_aside="التخزين جانباً: ابحث في Redis أولاً؛ وعند الغياب اسأل قاعدة البيانات واحفظ الجواب",
        w_c_ttl="يُنسى بعد 60 ثانية، حتى لو لم يحذفه أحد",
        w_c_change="تغيير البيانات: حدّث قاعدة البيانات أولاً، ثم احذف النسخة المخزنة",
        w_c_lock="الطلب الذي يأخذ القفل وحده يسأل قاعدة البيانات؛ والباقون ينتظرون ثم يبحثون مرة أخرى",
        w_c_token="رمز عشوائي: صاحب القفل وحده يحرره",
        w_c_release="احذف القفل فقط إن كان ما زال لنا، في خطوة واحدة على الخادم",
        w_c_window="عداد لكل عميل؛ وأول طلب يبدأ نافذة من 10 ثوانٍ",
        w_c_multi="MULTI/EXEC: الأمران ينفذان معاً، ولا شيء بينهما",
        w_c_servers="خادمان، واتصالان، وRedis واحد: الحد مشترك",
        w_c_fork="عشرون عملية، لكل منها اتصالاتها، كعشرين عامل PHP",
        w_d_first="الطلب الأول", w_d_second="الطلب الثاني", w_d_third="الطلب الثالث",
        w_d_after="بعد التغيير", w_d_from="من", w_d_in="في",
        w_d_changed="تغير السعر إلى 47000، وحُذفت النسخة المخزنة", w_d_left="الثواني الباقية في Redis:",
        w_d_requests="طلباً", w_d_queries="استعلامات قاعدة البيانات",
        w_d_request="الطلب", w_d_via="عبر الخادم", w_d_allowed="مسموح", w_d_of="من",
        w_d_refused="مرفوض، 429، حاول بعد", w_d_refused_short="مرفوض، 429", w_d_seconds="ث",
        w_s_strings="النصوص والعدادات وانتهاء الصلاحية",
        w_s_types="الجداول المصغرة والمجموعات المرتبة",
        w_s_cache="ذاكرة مؤقتة أمام استعلام بطيء",
        w_s_stampede="عشرون طلباً على ذاكرة مؤقتة باردة",
        w_s_rate="خمسة طلبات كل 10 ثوانٍ، يتقاسمها خادمان",
        w_c_sliding="التمرين 5: نافذة منزلقة، عضو في مجموعة مرتبة لكل طلب، ودرجته وقته",
        w_d_wait="(بعد ثانيتين)",
    ),
}

FILES = {
    "schema.sql": '''CREATE TABLE products (
  id    bigint PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL CHECK (price > 0)
);
INSERT INTO products VALUES (1, '{w_kit}', 45000), (2, '{w_wheels}', 6000);
''',
    "node/cache.ts": '''import pg from "pg";
import { createClient } from "redis";

const db = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop" });
const redis = await createClient({ url: "redis://localhost:6379" }).connect();
type Product = { id: string; name: string; price: number };

// {w_c_slow}
async function productFromDb(id: number): Promise<Product> {
  const sql = "SELECT id, name, price FROM products, pg_sleep(0.2) WHERE id = $1";
  return (await db.query(sql, [id])).rows[0];
}

// {w_c_aside}
async function product(id: number) {
  const key = `product:${id}`;
  const cached = await redis.get(key);
  if (cached !== null) return { product: JSON.parse(cached) as Product, from: "Redis" };
  const fresh = await productFromDb(id);
  // {w_c_ttl}
  await redis.set(key, JSON.stringify(fresh), { EX: 60 });
  return { product: fresh, from: "PostgreSQL" };
}

// {w_c_change}
async function setPrice(id: number, price: number) {
  await db.query("UPDATE products SET price = $1 WHERE id = $2", [price, id]);
  await redis.del(`product:${id}`);
}

async function timed(label: string, id: number) {
  const start = performance.now();
  const { product: p, from } = await product(id);
  const ms = Math.round(performance.now() - start);
  console.log(`${label.padEnd(16)} ${p.name}, ${p.price}, {w_d_from} ${from} {w_d_in} ${ms} ms`);
}

await redis.del("product:1");
await timed("{w_d_first}", 1);
await timed("{w_d_second}", 1);
await timed("{w_d_third}", 1);
await setPrice(1, 47000);
console.log("{w_d_changed}");
await timed("{w_d_after}", 1);
console.log("{w_d_left}", await redis.ttl("product:1"));
await redis.close();
await db.end();
''',
    "node/stampede.ts": '''import { randomUUID } from "node:crypto";
import { setTimeout as sleep } from "node:timers/promises";
import pg from "pg";
import { createClient } from "redis";

const db = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop" });
const redis = await createClient({ url: "redis://localhost:6379" }).connect();
const mode = process.argv[2] ?? "naive";

async function productFromDb(id: number) {
  // {w_c_count}
  await redis.incr("stats:db-queries");
  const sql = "SELECT id, name, price FROM products, pg_sleep(0.2) WHERE id = $1";
  return (await db.query(sql, [id])).rows[0];
}

// {w_c_release}
const RELEASE = `if redis.call("GET", KEYS[1]) == ARGV[1]
  then return redis.call("DEL", KEYS[1]) else return 0 end`;

async function product(id: number) {
  const key = `product:${id}`;
  for (;;) {
    const cached = await redis.get(key);
    if (cached !== null) return JSON.parse(cached);
    if (mode === "naive") break;
    // {w_c_lock}
    const token = randomUUID(); // {w_c_token}
    if (await redis.set(`lock:${key}`, token, { NX: true, PX: 5000 })) {
      try {
        const fresh = await productFromDb(id);
        await redis.set(key, JSON.stringify(fresh), { EX: 60 });
        return fresh;
      } finally {
        await redis.eval(RELEASE, { keys: [`lock:${key}`], arguments: [token] });
      }
    }
    await sleep(50);
  }
  const fresh = await productFromDb(id);
  await redis.set(key, JSON.stringify(fresh), { EX: 60 });
  return fresh;
}

await redis.del(["product:1", "stats:db-queries"]);
const start = performance.now();
await Promise.all(Array.from({ length: 20 }, () => product(1)));
const ms = Math.round(performance.now() - start);
const queries = await redis.get("stats:db-queries");
console.log(`${mode.padEnd(7)} 20 {w_d_requests}, {w_d_queries}: ${queries}, ${ms} ms`);
await redis.close();
await db.end();
''',
    "node/ratelimit.ts": '''import { createClient } from "redis";

const LIMIT = 5;
const WINDOW = 10; // seconds

// {w_c_window}
async function allow(redis: ReturnType<typeof createClient>, client: string) {
  const key = `rate:${client}`;
  // {w_c_multi}
  const [count] = await redis.multi().incr(key).expire(key, WINDOW, "NX").exec();
  return { allowed: Number(count) <= LIMIT, count: Number(count), key };
}

// {w_c_servers}
const servers = {
  A: await createClient({ url: "redis://localhost:6379" }).connect(),
  B: await createClient({ url: "redis://localhost:6379" }).connect(),
};
await servers.A.del("rate:203.0.113.7");
for (let i = 1; i <= 8; i++) {
  const name = i % 2 === 1 ? "A" : "B";
  const redis = servers[name];
  const { allowed, count, key } = await allow(redis, "203.0.113.7");
  const answer = allowed
    ? `{w_d_allowed} (${count} {w_d_of} ${LIMIT})`
    : `{w_d_refused} ${await redis.ttl(key)} {w_d_seconds}`;
  console.log(`{w_d_request} ${i} {w_d_via} ${name}: ${answer}`);
}
await servers.A.close();
await servers.B.close();
''',
    "node/sliding.ts": '''import { setTimeout as sleep } from "node:timers/promises";
import { createClient } from "redis";

const LIMIT = 3;
const WINDOW_MS = 2000;
const redis = await createClient({ url: "redis://localhost:6379" }).connect();

// {w_c_sliding}
async function allow(client: string) {
  const key = `sliding:${client}`;
  const now = Date.now();
  const [, , count] = await redis
    .multi()
    .zRemRangeByScore(key, 0, now - WINDOW_MS)
    .zAdd(key, { score: now, value: `${now}-${Math.random()}` })
    .zCard(key)
    .pExpire(key, WINDOW_MS)
    .exec();
  return Number(count) <= LIMIT;
}

await redis.del("sliding:203.0.113.7");
for (let i = 1; i <= 5; i++) {
  if (i === 5) {
    await sleep(2000);
    console.log("{w_d_wait}");
  }
  const allowed = await allow("203.0.113.7");
  console.log(`{w_d_request} ${i}: ${allowed ? "{w_d_allowed}" : "{w_d_refused_short}"}`);
}
await redis.close();
''',
    "php/composer.json": '''{
    "require": {
        "predis/predis": "3.7.1"
    }
}
''',
    "php/cache.php": '''<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

$db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
$redis = new Predis\\Client('tcp://localhost:6379');

// {w_c_slow}
function productFromDb(PDO $db, int $id): array
{
    $query = $db->prepare('SELECT id, name, price FROM products, pg_sleep(0.2) WHERE id = ?');
    $query->execute([$id]);

    return $query->fetch();
}

// {w_c_aside}
function product(PDO $db, Predis\\Client $redis, int $id): array
{
    $key = "product:$id";
    $cached = $redis->get($key);
    if ($cached !== null) {
        return [json_decode($cached, true), 'Redis'];
    }
    $fresh = productFromDb($db, $id);
    // {w_c_ttl}
    $redis->set($key, json_encode($fresh), 'EX', 60);

    return [$fresh, 'PostgreSQL'];
}

// {w_c_change}
function setPrice(PDO $db, Predis\\Client $redis, int $id, int $price): void
{
    $db->prepare('UPDATE products SET price = ? WHERE id = ?')->execute([$price, $id]);
    $redis->del("product:$id");
}

$timed = function (string $label, int $id) use ($db, $redis): void {
    $start = hrtime(true);
    [$product, $from] = product($db, $redis, $id);
    $ms = round((hrtime(true) - $start) / 1e6);
    printf("%s %s, %d, {w_d_from} %s {w_d_in} %d ms\\n",
        mb_str_pad($label, 16), $product['name'], $product['price'], $from, $ms);
};

$redis->del('product:1');
$timed('{w_d_first}', 1);
$timed('{w_d_second}', 1);
$timed('{w_d_third}', 1);
setPrice($db, $redis, 1, 47000);
echo "{w_d_changed}\\n";
$timed('{w_d_after}', 1);
echo '{w_d_left} ', $redis->ttl('product:1'), "\\n";
''',
    "php/stampede.php": '''<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

$mode = $argv[1] ?? 'naive';
$connect = fn () => new Predis\\Client('tcp://localhost:6379');

function productFromDb(Predis\\Client $redis, int $id): array
{
    // {w_c_count}
    $redis->incr('stats:db-queries');
    $db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret');
    $query = $db->prepare('SELECT id, name, price FROM products, pg_sleep(0.2) WHERE id = ?');
    $query->execute([$id]);

    return $query->fetch(PDO::FETCH_ASSOC);
}

// {w_c_release}
const RELEASE = <<<'LUA'
    if redis.call("GET", KEYS[1]) == ARGV[1]
      then return redis.call("DEL", KEYS[1]) else return 0 end
    LUA;

function product(Predis\\Client $redis, string $mode, int $id): array
{
    $key = "product:$id";
    while (true) {
        $cached = $redis->get($key);
        if ($cached !== null) {
            return json_decode($cached, true);
        }
        if ($mode === 'naive') {
            break;
        }
        // {w_c_lock}
        $token = bin2hex(random_bytes(16)); // {w_c_token}
        if ($redis->set("lock:$key", $token, 'PX', 5000, 'NX')) {
            try {
                $fresh = productFromDb($redis, $id);
                $redis->set($key, json_encode($fresh), 'EX', 60);

                return $fresh;
            } finally {
                $redis->eval(RELEASE, 1, "lock:$key", $token);
            }
        }
        usleep(50_000);
    }
    $fresh = productFromDb($redis, $id);
    $redis->set($key, json_encode($fresh), 'EX', 60);

    return $fresh;
}

$connect()->del(['product:1', 'stats:db-queries']);
$start = hrtime(true);
// {w_c_fork}
$children = [];
foreach (range(1, 20) as $request) {
    $pid = pcntl_fork();
    if ($pid === 0) {
        product($connect(), $mode, 1);
        exit(0);
    }
    $children[] = $pid;
}
foreach ($children as $pid) {
    pcntl_waitpid($pid, $status);
}
$ms = round((hrtime(true) - $start) / 1e6);
$queries = $connect()->get('stats:db-queries');
printf("%-7s 20 {w_d_requests}, {w_d_queries}: %d, %d ms\\n", $mode, $queries, $ms);
''',
    "php/sliding.php": '''<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

const LIMIT = 3;
const WINDOW_MS = 2000;
$redis = new Predis\\Client('tcp://localhost:6379');

// {w_c_sliding}
function allow(Predis\\Client $redis, string $client): bool
{
    $key = "sliding:$client";
    $now = (int) (microtime(true) * 1000);
    [, , $count] = $redis->transaction(function ($tx) use ($key, $now) {
        $tx->zremrangebyscore($key, 0, $now - WINDOW_MS);
        $tx->zadd($key, [$now.'-'.mt_rand() => $now]);
        $tx->zcard($key);
        $tx->pexpire($key, WINDOW_MS);
    });

    return $count <= LIMIT;
}

$redis->del('sliding:203.0.113.7');
foreach (range(1, 5) as $i) {
    if ($i === 5) {
        usleep(2_000_000);
        echo "{w_d_wait}\\n";
    }
    $allowed = allow($redis, '203.0.113.7');
    echo "{w_d_request} $i: ", $allowed ? '{w_d_allowed}' : '{w_d_refused_short}', "\\n";
}
''',
    "php/ratelimit.php": '''<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

const LIMIT = 5;
const WINDOW = 10; // seconds

// {w_c_window}
function allow(Predis\\Client $redis, string $client): array
{
    $key = "rate:$client";
    // {w_c_multi}
    [$count] = $redis->transaction(function ($tx) use ($key) {
        $tx->incr($key);
        $tx->expire($key, WINDOW, 'NX');
    });

    return [$count <= LIMIT, $count, $key];
}

// {w_c_servers}
$servers = [
    'A' => new Predis\\Client('tcp://localhost:6379'),
    'B' => new Predis\\Client('tcp://localhost:6379'),
];
$servers['A']->del('rate:203.0.113.7');
foreach (range(1, 8) as $i) {
    $name = $i % 2 === 1 ? 'A' : 'B';
    $redis = $servers[$name];
    [$allowed, $count, $key] = allow($redis, '203.0.113.7');
    $answer = $allowed
        ? "{w_d_allowed} ($count {w_d_of} ".LIMIT.')'
        : '{w_d_refused} '.$redis->ttl($key).' {w_d_seconds}';
    echo "{w_d_request} $i {w_d_via} $name: $answer\\n";
}
''',
}


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    subprocess.run(["redis-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("psql shop -q -f schema.sql")
    s.run("cd php && composer install -q --no-progress 2>&1")
    s.lines.clear()

    s.note(t["w_s_strings"])
    s.run("redis-cli SET greeting hello")
    s.run("redis-cli GET greeting")
    s.run("redis-cli GET nothing")
    s.run("redis-cli INCR visits")
    s.run("redis-cli INCR visits")
    s.run("redis-cli SET session:7f3a 42 EX 1800")
    s.run("redis-cli TTL session:7f3a")
    s.run("redis-cli SET once yes NX")
    s.run("redis-cli SET once again NX")
    s.save(folder / "strings.sh")
    s.note(t["w_s_types"])
    s.run(f"redis-cli HSET product:2 name '{t['w_wheels']}' price 6000")
    s.run("redis-cli HGET product:2 price")
    s.run(f"redis-cli ZADD scores 120 {t['w_sara']} 95 {t['w_omar']} 140 {t['w_lina']}")
    s.run("redis-cli ZINCRBY scores 30 " + t["w_omar"])
    s.run("redis-cli ZREVRANGE scores 0 2 WITHSCORES")
    s.save(folder / "types.sh")

    for ed, cmd in (("node", "node node/{}.ts"), ("php", "php php/{}.php")):
        s.note(t["w_s_cache"])
        s.run("psql shop -q -c 'UPDATE products SET price = 45000 WHERE id = 1'")
        s.lines.pop()
        s.run(cmd.format("cache"))
        s.save(folder / f"{ed}-cache.sh")
        s.note(t["w_s_stampede"])
        s.run(cmd.format("stampede") + " naive")
        s.run(cmd.format("stampede") + " locked")
        s.save(folder / f"{ed}-stampede.sh")
        s.note(t["w_s_rate"])
        s.run(cmd.format("ratelimit"))
        s.save(folder / f"{ed}-ratelimit.sh")
        s.run(cmd.format("sliding"))
        s.save(folder / f"{ed}-answers.sh")


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    os.symlink(B3 / "node_modules", folder / "node_modules")
    record(folder, t)
    (folder / "node_modules").unlink()
    shutil.rmtree(folder / "php" / "vendor")
    print("wrote", lang)
