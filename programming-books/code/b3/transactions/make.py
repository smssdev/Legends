"""Writes the examples of Book 3, the shared chapter "Transactions, Locks and Consistency".
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start; PHP through bin/php)

Concurrency, for real: ten buyers race for the last robot kit (naive, atomic update, row lock, serializable
with retries), two connections show what each isolation level lets a transaction see, and two transactions
deadlock. Each edition has its own programs with the same behaviour: node/*.ts with the pg driver, php/*.php
with PDO (parallel buyers with pcntl_fork). What the terminal showed is saved as transcripts (*.sh).
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
        w_kit="Robot kit", w_wheels="Spare wheels",
        w_c_gap="the time a real app spends between reading and writing: a call to a payment service, say",
        w_c_naive="read, decide in code, write: the classic race",
        w_c_atomic="one statement: the database checks and changes the stock together",
        w_c_lock="FOR UPDATE locks the row: other buyers wait here until this transaction ends",
        w_c_serial="the database detects the conflict and refuses one transaction; try it again",
        w_c_retry="serialization failure: start the whole transaction again",
        w_c_isolation="A reads, B changes and commits, A reads again, then A tries to change it",
        w_c_dead="A locks product 1 then 2; B locks 2 then 1",
        w_c_close="closed before forking: a child must never share its parent's connection",
        w_c_ten="Ten processes, each with its own connection, buying at the same moment.",
        w_c_ordered="\"ordered\": both lock the lower id first (the answer to exercise 3)",
        w_c_echo="one echo: two processes print at once",
        w_d_stock="in stock", w_d_sold="sold", w_d_now="stock now", w_d_retries="retries",
        w_d_a_first="A reads the price", w_d_b_change="B sets the price to 50000 and commits",
        w_d_a_again="A reads it again", w_d_a_update="A adds 1000 to the price",
        w_d_failed="failed", w_d_done="done",
        w_s_basics="A transaction: all or nothing",
        w_s_atomic="One step fails, so nothing happens",
        w_s_race="Ten buyers, one robot kit, four ways to sell it",
        w_s_rc="READ COMMITTED (PostgreSQL's default)", w_s_rr="REPEATABLE READ",
        w_s_dead="Two transactions, the same two rows, in opposite orders",
    ),
    "ar": dict(
        w_kit="عدة الروبوت", w_wheels="عجلات احتياطية",
        w_c_gap="الوقت الذي يمضيه تطبيق حقيقي بين القراءة والكتابة: استدعاء خدمة دفع مثلاً",
        w_c_naive="اقرأ، وقرر في الكود، ثم اكتب: السباق الكلاسيكي",
        w_c_atomic="جملة واحدة: تفحص قاعدة البيانات المخزون وتغيّره معاً",
        w_c_lock="FOR UPDATE تقفل الصف: ينتظر المشترون الآخرون هنا حتى تنتهي هذه المعاملة",
        w_c_serial="تكتشف قاعدة البيانات التعارض وترفض إحدى المعاملتين، فأعدها",
        w_c_retry="فشل التسلسل: ابدأ المعاملة كلها من جديد",
        w_c_isolation="A تقرأ، وB تغيّر وتثبّت، وA تقرأ مرة أخرى، ثم تحاول A أن تغيّر",
        w_c_dead="A تقفل المنتج 1 ثم 2، وB تقفل 2 ثم 1",
        w_c_close="تُغلق قبل التفرع: لا يشارك ابن اتصال أبيه أبداً",
        w_c_ten="عشر عمليات، لكل منها اتصالها، تشتري في اللحظة نفسها.",
        w_c_ordered="\"ordered\": كلتاهما تقفل الرقم الأصغر أولاً (جواب التمرين 3)",
        w_c_echo="echo واحدة: عمليتان تطبعان معاً",
        w_d_stock="في المخزون", w_d_sold="مبيعات", w_d_now="المخزون الآن", w_d_retries="إعادات",
        w_d_a_first="A تقرأ السعر", w_d_b_change="B تضبط السعر على 50000 وتثبّت",
        w_d_a_again="A تقرؤه مرة أخرى", w_d_a_update="A تضيف 1000 إلى السعر",
        w_d_failed="فشلت", w_d_done="انتهت",
        w_s_basics="المعاملة: كل شيء أو لا شيء",
        w_s_atomic="خطوة تفشل، فلا يحدث شيء",
        w_s_race="عشرة مشترين، وعدّة روبوت واحدة، وأربع طرق لبيعها",
        w_s_rc="READ COMMITTED (افتراضي PostgreSQL)", w_s_rr="REPEATABLE READ",
        w_s_dead="معاملتان، والصفان نفسهما، بترتيبين متعاكسين",
    ),
}

FILES = {
    "schema.sql": '''CREATE TABLE products (
  id    bigint PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL CHECK (price > 0),
  stock integer NOT NULL CHECK (stock >= 0)
);
CREATE TABLE orders (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products (id),
  buyer      integer NOT NULL
);
INSERT INTO products VALUES (1, '{w_kit}', 45000, 1), (2, '{w_wheels}', 6000, 10);
''',
    "basics.sql": '''BEGIN;
UPDATE products SET stock = stock + 5 WHERE id = 2;
SELECT name, stock FROM products WHERE id = 2;
ROLLBACK;
SELECT name, stock FROM products WHERE id = 2;
''',
    "atomic.sql": '''BEGIN;
UPDATE products SET stock = stock - 1 WHERE id = 2;
UPDATE products SET stock = stock - 100 WHERE id = 1;
SELECT name, stock FROM products;
COMMIT;
SELECT name, stock FROM products;
''',
    "node/race.ts": '''import pg from "pg";

const url = "postgres://bit:secret@localhost:5432/shop";
const mode = process.argv[2] ?? "naive";
let retries = 0;

async function buy(buyer: number) {
  const db = new pg.Client(url);
  await db.connect();
  try {
    for (;;) {
      try {
        await db.query(mode === "serializable" ? "BEGIN ISOLATION LEVEL SERIALIZABLE" : "BEGIN");
        if (mode === "atomic") {
          // {w_c_atomic}
          const taken = await db.query(
            "UPDATE products SET stock = stock - 1 WHERE id = 1 AND stock > 0",
          );
          if (taken.rowCount === 1) {
            await db.query("INSERT INTO orders (product_id, buyer) VALUES (1, $1)", [buyer]);
          }
        } else {
          // {w_c_naive}
          // {w_c_lock}
          const lock = mode === "lock" ? " FOR UPDATE" : "";
          const { rows } = await db.query(`SELECT stock FROM products WHERE id = 1${lock}`);
          // {w_c_gap}
          await db.query("SELECT pg_sleep(0.1)");
          if (rows[0].stock > 0) {
            await db.query("UPDATE products SET stock = $1 WHERE id = 1", [rows[0].stock - 1]);
            await db.query("INSERT INTO orders (product_id, buyer) VALUES (1, $1)", [buyer]);
          }
        }
        await db.query("COMMIT");
        return;
      } catch (error) {
        await db.query("ROLLBACK");
        // {w_c_retry}
        if ((error as { code?: string }).code !== "40001") throw error;
        retries++;
      }
    }
  } finally {
    await db.end();
  }
}

const admin = new pg.Client(url);
await admin.connect();
await admin.query("TRUNCATE orders; UPDATE products SET stock = 1 WHERE id = 1");
await Promise.all(Array.from({ length: 10 }, (_, i) => buy(i + 1)));
const sold = (await admin.query("SELECT count(*)::int AS n FROM orders")).rows[0].n;
const stock = (await admin.query("SELECT stock FROM products WHERE id = 1")).rows[0].stock;
console.log(
  `${mode.padEnd(12)} 1 {w_d_stock}, ${sold} {w_d_sold}, {w_d_now} ${stock}` +
    (mode === "serializable" ? `, ${retries} {w_d_retries}` : ""),
);
await admin.end();
''',
    "node/isolation.ts": '''import pg from "pg";

const url = "postgres://bit:secret@localhost:5432/shop";
const level = process.argv[2] ?? "READ COMMITTED";
const a = new pg.Client(url);
const b = new pg.Client(url);
await a.connect();
await b.connect();
const price = async () => (await a.query("SELECT price FROM products WHERE id = 1")).rows[0].price;

// {w_c_isolation}
await a.query(`BEGIN ISOLATION LEVEL ${level}`);
console.log("{w_d_a_first}:", await price());
await b.query("UPDATE products SET price = 50000 WHERE id = 1");
console.log("{w_d_b_change}");
console.log("{w_d_a_again}:", await price());
try {
  await a.query("UPDATE products SET price = price + 1000 WHERE id = 1");
  await a.query("COMMIT");
  console.log("{w_d_a_update}:", (await a.query("SELECT price FROM products WHERE id = 1")).rows[0].price);
} catch (error) {
  await a.query("ROLLBACK");
  console.log("{w_d_a_update}: ERROR", (error as Error).message);
}
await b.query("UPDATE products SET price = 45000 WHERE id = 1");
await a.end();
await b.end();
''',
    "node/deadlock.ts": '''import pg from "pg";
import { setTimeout as sleep } from "node:timers/promises";

const url = "postgres://bit:secret@localhost:5432/shop";
const take = (db: pg.Client, id: number) =>
  db.query("UPDATE products SET stock = stock + 1 WHERE id = $1", [id]);

// {w_c_dead}
async function run(name: string, first: number, second: number) {
  const db = new pg.Client(url);
  await db.connect();
  try {
    await db.query("BEGIN");
    await take(db, first);
    await sleep(200);
    await take(db, second);
    await db.query("COMMIT");
    console.log(`${name}: {w_d_done}`);
  } catch (error) {
    await db.query("ROLLBACK");
    console.log(`${name}: {w_d_failed}, ${(error as { code?: string }).code}, ${(error as Error).message}`);
  } finally {
    await db.end();
  }
}

// {w_c_ordered}
const ordered = process.argv[2] === "ordered";
await Promise.all([run("A", 1, 2), ordered ? run("B", 1, 2) : run("B", 2, 1)]);
''',
    "php/race.php": '''<?php

declare(strict_types=1);

$connect = fn () => new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$mode = $argv[1] ?? 'naive';

function buy(PDO $db, string $mode, int $buyer): int
{
    $retries = 0;
    while (true) {
        try {
            $db->exec($mode === 'serializable' ? 'BEGIN ISOLATION LEVEL SERIALIZABLE' : 'BEGIN');
            if ($mode === 'atomic') {
                // {w_c_atomic}
                $taken = $db->exec('UPDATE products SET stock = stock - 1 WHERE id = 1 AND stock > 0');
                if ($taken === 1) {
                    $db->prepare('INSERT INTO orders (product_id, buyer) VALUES (1, ?)')->execute([$buyer]);
                }
            } else {
                // {w_c_naive}
                // {w_c_lock}
                $lock = $mode === 'lock' ? ' FOR UPDATE' : '';
                $stock = (int) $db->query("SELECT stock FROM products WHERE id = 1$lock")->fetchColumn();
                // {w_c_gap}
                $db->query('SELECT pg_sleep(0.1)');
                if ($stock > 0) {
                    $db->prepare('UPDATE products SET stock = ? WHERE id = 1')->execute([$stock - 1]);
                    $db->prepare('INSERT INTO orders (product_id, buyer) VALUES (1, ?)')->execute([$buyer]);
                }
            }
            $db->exec('COMMIT');
            return $retries;
        } catch (PDOException $e) {
            $db->exec('ROLLBACK');
            // {w_c_retry}
            if ($e->getCode() !== '40001') {
                throw $e;
            }
            $retries++;
        }
    }
}

$setup = $connect();
$setup->exec('TRUNCATE orders; UPDATE products SET stock = 1 WHERE id = 1');
$setup = null; // {w_c_close}

// {w_c_ten}
$children = [];
foreach (range(1, 10) as $buyer) {
    $pid = pcntl_fork();
    if ($pid === 0) {
        exit(buy($connect(), $mode, $buyer));
    }
    $children[] = $pid;
}
$retries = 0;
foreach ($children as $pid) {
    pcntl_waitpid($pid, $status);
    $retries += pcntl_wexitstatus($status);
}

$admin = $connect();
$sold = $admin->query('SELECT count(*) FROM orders')->fetchColumn();
$stock = $admin->query('SELECT stock FROM products WHERE id = 1')->fetchColumn();
printf("%-12s 1 {w_d_stock}, %d {w_d_sold}, {w_d_now} %d%s\\n", $mode, $sold, $stock,
    $mode === 'serializable' ? ", $retries {w_d_retries}" : '');
''',
    "php/isolation.php": '''<?php

declare(strict_types=1);

$connect = fn () => new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$level = $argv[1] ?? 'READ COMMITTED';
$a = $connect();
$b = $connect();
$price = fn () => $a->query('SELECT price FROM products WHERE id = 1')->fetchColumn();

// {w_c_isolation}
$a->exec("BEGIN ISOLATION LEVEL $level");
echo '{w_d_a_first}: ', $price(), "\\n";
$b->exec('UPDATE products SET price = 50000 WHERE id = 1');
echo "{w_d_b_change}\\n";
echo '{w_d_a_again}: ', $price(), "\\n";
try {
    $a->exec('UPDATE products SET price = price + 1000 WHERE id = 1');
    $a->exec('COMMIT');
    echo '{w_d_a_update}: ', $price(), "\\n";
} catch (PDOException $e) {
    $a->exec('ROLLBACK');
    echo '{w_d_a_update}: ERROR ', preg_replace('/^ERROR:\\s+/', '', $e->errorInfo[2]), "\\n";
}
$b->exec('UPDATE products SET price = 45000 WHERE id = 1');
''',
    "php/deadlock.php": '''<?php

declare(strict_types=1);

// {w_c_dead}
function run(string $name, int $first, int $second): void
{
    $db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $take = $db->prepare('UPDATE products SET stock = stock + 1 WHERE id = ?');
    try {
        $db->exec('BEGIN');
        $take->execute([$first]);
        usleep(200_000);
        $take->execute([$second]);
        $db->exec('COMMIT');
        echo "$name: {w_d_done}\\n";
    } catch (PDOException $e) {
        $db->exec('ROLLBACK');
        $message = preg_replace('/^ERROR:\\s+/', '', strtok($e->errorInfo[2], "\\n"));
        echo "$name: {w_d_failed}, {$e->getCode()}, $message\\n"; // {w_c_echo}
    }
}

$pid = pcntl_fork();
if ($pid === 0) {
    // {w_c_ordered}
    ($argv[1] ?? '') === 'ordered' ? run('B', 1, 2) : run('B', 2, 1);
    exit(0);
}
run('A', 1, 2);
pcntl_waitpid($pid, $status);
''',
}


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("psql shop -q -f schema.sql")
    s.lines.clear()
    s.note(t["w_s_basics"])
    s.run("psql shop -a -f basics.sql 2>&1")
    s.save(folder / "basics.sh")
    s.note(t["w_s_atomic"])
    s.run("psql shop -a -f atomic.sql 2>&1", check=False)
    s.save(folder / "atomic.sh")
    for ed, cmd in (("node", "node node/{}.ts"), ("php", "php php/{}.php")):
        s.note(t["w_s_race"])
        for mode in ("naive", "atomic", "lock", "serializable"):
            s.run(cmd.format("race") + " " + mode)
        s.save(folder / f"{ed}-race.sh")
        s.note(t["w_s_rc"])
        s.run(cmd.format("isolation"))
        s.note(t["w_s_rr"])
        s.run(cmd.format("isolation") + " 'REPEATABLE READ'")
        s.save(folder / f"{ed}-isolation.sh")
        s.note(t["w_s_dead"])
        s.run(cmd.format("deadlock"))
        s.save(folder / f"{ed}-deadlock.sh")
        s.run(cmd.format("deadlock") + " ordered")
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
    print("wrote", lang)
