"""Writes the examples of Book 3, the shared chapter "Performance".
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start; PHP through bin/php)

Measured, not guessed: a table of 500,000 products, a query plan before and after an index, and a load test
with autocannon against each edition's server (node/server.ts with Fastify, php/router.php on PHP's built-in
server) before and after; then each runtime's own limit: Node's single event loop, blocked by synchronous
work and freed by moving it to the thread pool, and PHP's workers, where concurrency is the number of
processes. What the terminal showed is saved as transcripts (*.sh).
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent
sys.path.insert(0, str(B3))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_data="500,000 products in 2,000 categories of 250 each",
        w_c_sync="DANGER: 100,000 rounds of hashing on the event loop: nothing else runs meanwhile",
        w_c_async="the same work on libuv's thread pool: the event loop stays free",
        w_c_pool="at most 10 connections: requests beyond that wait for one",
        w_c_slow="a call to another service that takes 100 ms, while the process waits",
        w_c_length="the length tells the client where the body ends (the built-in server does not say)",
        w_s_explain="The query plan, without an index",
        w_s_load="20 clients for 5 seconds, without an index",
        w_s_index="An index that matches the query",
        w_s_explain_after="The same query plan, with the index",
        w_s_load_after="The same load, with the index",
        w_s_ping_sync="/ping, while other clients call /hash/sync",
        w_s_ping_async="/ping, while other clients call /hash/async",
        w_s_ping_alone="/ping alone, for comparison",
        w_s_one="One PHP worker: 8 clients call a route that waits 100 ms",
        w_s_four="Four PHP workers, the same load",
    ),
    "ar": dict(
        w_c_data="500000 منتج في 2000 تصنيف، في كل منها 250",
        w_c_sync="خطر: 100000 جولة تجزئة على حلقة الأحداث: لا شيء آخر يعمل في الأثناء",
        w_c_async="العمل نفسه على مجمّع خيوط libuv: تبقى حلقة الأحداث حرة",
        w_c_pool="10 اتصالات على الأكثر: الطلبات الزائدة تنتظر واحداً",
        w_c_slow="استدعاء لخدمة أخرى يستغرق 100 مللي ثانية، والعملية تنتظر",
        w_c_length="الطول يخبر العميل أين ينتهي الجسم (الخادم المبني لا يقوله)",
        w_s_explain="خطة الاستعلام، بلا فهرس",
        w_s_load="20 عميلاً لمدة 5 ثوانٍ، بلا فهرس",
        w_s_index="فهرس يطابق الاستعلام",
        w_s_explain_after="خطة الاستعلام نفسها، بالفهرس",
        w_s_load_after="الحمل نفسه، بالفهرس",
        w_s_ping_sync="/ping، بينما ينادي عملاء آخرون /hash/sync",
        w_s_ping_async="/ping، بينما ينادي عملاء آخرون /hash/async",
        w_s_ping_alone="/ping وحده، للمقارنة",
        w_s_one="عامل PHP واحد: 8 عملاء ينادون مساراً ينتظر 100 مللي ثانية",
        w_s_four="أربعة عمّال PHP، والحمل نفسه",
    ),
}

FILES = {
    "schema.sql": '''-- {w_c_data}
CREATE TABLE products (
  id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name     text NOT NULL,
  category text NOT NULL,
  price    integer NOT NULL
);
INSERT INTO products (name, category, price)
SELECT 'Product ' || n,
       (ARRAY['kits', 'wheels', 'cables', 'sensors', 'motors', 'tools', 'lights', 'cases'])[1 + n % 8]
         || '-' || (n % 250),
       (n * 37) % 100000 + 100
FROM generate_series(1, 500000) AS n;
ANALYZE products;
''',
    "query.sql": '''EXPLAIN (ANALYZE, COSTS OFF)
SELECT id, name, price FROM products
WHERE category = 'cables-42'
ORDER BY price
LIMIT 20;
''',
    "node/server.ts": '''import { pbkdf2, pbkdf2Sync } from "node:crypto";
import { promisify } from "node:util";
import Fastify from "fastify";
import pg from "pg";

// {w_c_pool}
const db = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop", max: 10 });
const app = Fastify();

app.get<{ Querystring: { category: string } }>("/products", async (request) => {
  const { rows } = await db.query(
    "SELECT id, name, price FROM products WHERE category = $1 ORDER BY price LIMIT 20",
    [request.query.category],
  );
  return rows;
});

app.get("/ping", async () => ({ ok: true }));

app.get("/hash/sync", async () => {
  // {w_c_sync}
  const key = pbkdf2Sync("password", "salt", 100_000, 32, "sha256");
  return { key: key.toString("hex").slice(0, 8) };
});

const pbkdf2Async = promisify(pbkdf2);
app.get("/hash/async", async () => {
  // {w_c_async}
  const key = await pbkdf2Async("password", "salt", 100_000, 32, "sha256");
  return { key: key.toString("hex").slice(0, 8) };
});

await app.listen({ port: 3000 });
''',
    "php/router.php": r'''<?php

declare(strict_types=1);

// {w_c_length}
function send(mixed $data): void
{
    $body = json_encode($data);
    header('Content-Type: application/json');
    header('Content-Length: '.strlen($body));
    echo $body;
}

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

if ($path === '/products') {
    $db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret');
    $query = $db->prepare('SELECT id, name, price FROM products WHERE category = ? ORDER BY price LIMIT 20');
    $query->execute([$_GET['category'] ?? '']);
    send($query->fetchAll(PDO::FETCH_ASSOC));
} elseif ($path === '/slow') {
    // {w_c_slow}
    usleep(100_000);
    send(['ok' => true]);
} else {
    send(['ok' => true]);
}
''',
}

SUMMARY = ("2>/dev/null | jq -c '{requests_per_s: .requests.average, p50_ms: .latency.p50, "
           "p99_ms: .latency.p99, errors: (.errors + .non2xx)}'")


# PHP's built-in server closes the connection after every response, which makes autocannon's latencies
# meaningless there; for PHP the transcripts keep the throughput only.
THROUGHPUT = "2>/dev/null | jq -c '{requests_per_s: .requests.average, errors: (.errors + .non2xx)}'"


def load(s, url, conns, secs, shown_extra=""):
    shown = f"npx autocannon -c {conns} -d {secs} {url}"
    summary = THROUGHPUT if ":8000" in url else SUMMARY
    s.run(f"npx autocannon -c {conns} -d {secs} -j {url} {summary}", shown=shown + shown_extra)


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("psql shop -q -f schema.sql")
    s.lines.clear()
    s.note(t["w_s_explain"])
    s.run("psql shop -f query.sql")
    s.save(folder / "explain.sh")

    url = "'localhost:{port}/products?category=cables-42'"
    with Server("node node/server.ts", folder, "http://localhost:3000/ping"):
        s.note(t["w_s_load"])
        load(s, url.format(port=3000), 20, 5)
        s.save(folder / "node-before.sh")
    with Server("PHP_CLI_SERVER_WORKERS=4 php -S localhost:8000 php/router.php", folder,
                "http://localhost:8000/ping"):
        s.note(t["w_s_load"])
        load(s, url.format(port=8000), 20, 5)
        s.save(folder / "php-before.sh")

    s.note(t["w_s_index"])
    s.run("psql shop -c 'CREATE INDEX products_category_price ON products (category, price)'")
    s.note(t["w_s_explain_after"])
    s.run("psql shop -f query.sql")
    s.save(folder / "explain-after.sh")

    with Server("node node/server.ts", folder, "http://localhost:3000/ping"):
        s.note(t["w_s_load_after"])
        load(s, url.format(port=3000), 20, 5)
        s.save(folder / "node-after.sh")
        for kind, note in (("sync", "w_s_ping_sync"), ("async", "w_s_ping_async")):
            s.note(t[note])
            s.run(f"npx autocannon -c 4 -d 6 localhost:3000/hash/{kind} > /dev/null 2>&1 & sleep 1; "
                  f"npx autocannon -c 10 -d 4 -j localhost:3000/ping {SUMMARY}; wait",
                  shown="npx autocannon -c 10 -d 4 localhost:3000/ping")
        s.note(t["w_s_ping_alone"])
        load(s, "localhost:3000/ping", 10, 4)
        s.save(folder / "node-loop.sh")
    with Server("PHP_CLI_SERVER_WORKERS=4 php -S localhost:8000 php/router.php", folder,
                "http://localhost:8000/ping"):
        s.note(t["w_s_load_after"])
        load(s, url.format(port=8000), 20, 5)
        s.save(folder / "php-after.sh")

    for workers, note in ((1, "w_s_one"), (4, "w_s_four")):
        with Server(f"PHP_CLI_SERVER_WORKERS={workers} php -S localhost:8000 php/router.php", folder,
                    "http://localhost:8000/ping"):
            s.note(t[note])
            s.add(f"$ PHP_CLI_SERVER_WORKERS={workers} php -S localhost:8000 php/router.php")
            load(s, "localhost:8000/slow", 8, 5)
    s.save(folder / "php-workers.sh")


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    os.symlink(B3 / "node_modules", folder / "node_modules")
    subprocess.run(["npx", "prettier", "--print-width", "84", "--write", "node"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
