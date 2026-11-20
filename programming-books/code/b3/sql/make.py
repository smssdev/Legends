"""Writes the examples of Book 3, the shared chapter "SQL and PostgreSQL", for both editions and languages.
Run: python3 make.py   (PostgreSQL 18 runs in Docker through code/b3/bin/pg-start and bin/psql)

The shop's schema and data (<lang>/schema.sql, seed.sql), the queries of the chapter, each run for real
with psql and saved as a transcript that looks like a psql session (*.sh), and a small program per edition
that talks to PostgreSQL from code: node/query.ts with the pg driver, php/query.php with PDO.
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
        w_products="('Robot kit', 45000, 10), ('Spare wheels', 6000, 25), ('Battery pack', 12500, 0), "
                   "('USB cable', 2500, 80), ('Servo motor', 9000, 14), ('Sensor set', 15000, 6), "
                   "('Remote control', 8000, 9), ('Solar panel', 30000, 3), ('Gear box', 11000, 12), "
                   "('LED strip', 4000, 40), ('Speaker', 7500, 18), ('Camera module', 21000, 5)",
        w_customers="('Sara', 'sara@example.com', 'Cairo'), ('Omar', 'omar@example.com', 'Alexandria'), "
                    "('Lina', 'lina@example.com', 'Cairo'), ('Karim', 'karim@example.com', NULL), "
                    "('Mona', 'mona@example.com', 'Giza'), ('Youssef', 'youssef@example.com', 'Cairo'), "
                    "('Hana', 'hana@example.com', 'Alexandria')",
        w_cairo="Cairo", w_cities="'Cairo', 'Alexandria', 'Giza', 'Aswan'",
        w_c_ids="the database numbers the rows itself; nobody sends an id",
        w_c_money="piastres: whole numbers, never fractions",
        w_c_never_negative="the database refuses negative stock, whatever the application does",
        w_c_status="only these four values can ever be stored",
        w_c_price="the price when the order was made: prices change, orders must not",
        w_c_pk="a product appears once per order",
        w_c_named="Seven customers by name, and two thousand more for the performance examples.",
        w_c_seed="The same random numbers on every run, so the book's numbers stay the same.",
        w_c_orders="A hundred thousand orders over the last year, from the generated customers.",
        w_c_items="One to three different products per order.",
        w_c_known="A few orders for the named customers, to read in the examples.",
        w_c_bad="What a form might send as an email: it closes the quote and adds a condition.",
        w_c_concat="WRONG: the input becomes part of the SQL",
        w_c_param="Right: the SQL and the value travel separately; $1 is only ever a value",
        w_c_bigint="count(*) is a bigint; pg returns it as a string, because JavaScript numbers cannot hold every bigint",
        w_c_pdo_param="Right: the SQL and the value travel separately; ? is only ever a value",
        w_c_pdo_errors="errors become exceptions, not silent false",
        w_d_unsafe="string concatenation", w_d_safe="parameter", w_d_rows="rows", w_d_count="orders",
        w_s_load="Create the tables, then fill them",
        w_s_describe="psql describes a table: columns, types, defaults, indexes and rules",
        w_s_select="Choose rows and columns, sort, keep the first few",
        w_s_null="NULL is not a value: = NULL is never true",
        w_s_rules="The database enforces its rules on every write",
        w_s_join="Join the tables: each named customer's orders with their totals",
        w_s_left="LEFT JOIN keeps customers without orders",
        w_s_group="The products that bring in the most money",
        w_s_window="A CTE and a window function: rank the named customers by what they spent",
        w_s_write="Writes that answer: RETURNING, and an upsert with ON CONFLICT",
        w_s_slow="How does PostgreSQL find one customer's orders?",
        w_s_index="Add an index on the foreign key, and ask again",
        w_s_expr="An index on an expression, for case-insensitive email lookups",
        w_s_node="From Node, with the pg driver", w_s_php="From PHP, with PDO",
    ),
    "ar": dict(
        w_products="('عدة الروبوت', 45000, 10), ('عجلات احتياطية', 6000, 25), ('حزمة بطارية', 12500, 0), "
                   "('كابل USB', 2500, 80), ('محرك سيرفو', 9000, 14), ('طقم حساسات', 15000, 6), "
                   "('جهاز تحكم', 8000, 9), ('لوح شمسي', 30000, 3), ('صندوق تروس', 11000, 12), "
                   "('شريط LED', 4000, 40), ('سماعة', 7500, 18), ('وحدة كاميرا', 21000, 5)",
        w_customers="('سارة', 'sara@example.com', 'القاهرة'), ('عمر', 'omar@example.com', 'الإسكندرية'), "
                    "('لينا', 'lina@example.com', 'القاهرة'), ('كريم', 'karim@example.com', NULL), "
                    "('منى', 'mona@example.com', 'الجيزة'), ('يوسف', 'youssef@example.com', 'القاهرة'), "
                    "('هناء', 'hana@example.com', 'الإسكندرية')",
        w_cairo="القاهرة", w_cities="'القاهرة', 'الإسكندرية', 'الجيزة', 'أسوان'",
        w_c_ids="تُرقّم قاعدة البيانات الصفوف بنفسها، ولا أحد يرسل رقماً",
        w_c_money="بالقروش: أعداد صحيحة، لا كسور أبداً",
        w_c_never_negative="ترفض قاعدة البيانات المخزون السالب، مهما فعل التطبيق",
        w_c_status="لا يمكن أن تُخزَّن إلا هذه القيم الأربع",
        w_c_price="السعر عند الطلب: الأسعار تتغير، والطلبات يجب ألا تتغير",
        w_c_pk="يظهر المنتج مرة واحدة في كل طلب",
        w_c_named="سبعة عملاء بأسمائهم، وألفان آخرون لأمثلة الأداء.",
        w_c_seed="الأعداد العشوائية نفسها في كل تشغيل، فتبقى أرقام الكتاب كما هي.",
        w_c_orders="مئة ألف طلب في السنة الماضية، من العملاء المولَّدين.",
        w_c_items="من منتج إلى ثلاثة منتجات مختلفة في كل طلب.",
        w_c_known="طلبات قليلة للعملاء المسمّين، لنقرأها في الأمثلة.",
        w_c_bad="ما قد يرسله نموذج على أنه بريد: يغلق علامة التنصيص ويضيف شرطاً.",
        w_c_concat="خطأ: المدخل يصير جزءاً من SQL",
        w_c_param="صحيح: SQL والقيمة يسافران منفصلين، و$1 قيمة دائماً لا غير",
        w_c_bigint="count(*) من النوع bigint، ويُرجعه pg نصاً لأن أعداد JavaScript لا تتسع لكل bigint",
        w_c_pdo_param="صحيح: SQL والقيمة يسافران منفصلين، و? قيمة دائماً لا غير",
        w_c_pdo_errors="الأخطاء تصير استثناءات، لا false صامتة",
        w_d_unsafe="وصل النصوص", w_d_safe="معامل", w_d_rows="صفوف", w_d_count="طلب",
        w_s_load="أنشئ الجداول، ثم املأها",
        w_s_describe="يصف psql الجدول: الأعمدة والأنواع والقيم الافتراضية والفهارس والقواعد",
        w_s_select="اختر الصفوف والأعمدة، ورتّب، واحتفظ بالأوائل",
        w_s_null="NULL ليست قيمة: = NULL لا تصدق أبداً",
        w_s_rules="تفرض قاعدة البيانات قواعدها مع كل كتابة",
        w_s_join="اربط الجداول: طلبات كل عميل مسمّى بإجمالياتها",
        w_s_left="LEFT JOIN تُبقي العملاء الذين لا طلبات لهم",
        w_s_group="المنتجات التي تجلب أكثر المال",
        w_s_window="CTE ودالة نافذة: رتّب العملاء المسمّين بما أنفقوه",
        w_s_write="كتابات تجيب: RETURNING، والإدراج أو التحديث بـ ON CONFLICT",
        w_s_slow="كيف تجد PostgreSQL طلبات عميل واحد؟",
        w_s_index="أضف فهرساً على المفتاح الأجنبي، واسأل مرة أخرى",
        w_s_expr="فهرس على تعبير، للبحث عن البريد دون اعتبار لحالة الحروف",
        w_s_node="من Node، بالمشغّل pg", w_s_php="من PHP، بـ PDO",
    ),
}

FILES = {
    "schema.sql": '''CREATE TABLE customers (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- {w_c_ids}
  name       text NOT NULL,
  email      text NOT NULL UNIQUE,
  city       text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE products (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL CHECK (price > 0), -- {w_c_money}
  stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0) -- {w_c_never_negative}
);

CREATE TABLE orders (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customers (id),
  status      text NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'paid', 'shipped', 'cancelled')), -- {w_c_status}
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
  order_id   bigint NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES products (id),
  quantity   integer NOT NULL CHECK (quantity BETWEEN 1 AND 99),
  price      integer NOT NULL, -- {w_c_price}
  PRIMARY KEY (order_id, product_id) -- {w_c_pk}
);
''',
    "seed.sql": '''INSERT INTO products (name, price, stock) VALUES
  {w_products};

-- {w_c_named}
INSERT INTO customers (name, email, city) VALUES
  {w_customers};
INSERT INTO customers (name, email, city, created_at)
SELECT 'customer-' || n, 'customer' || n || '@example.com',
       (ARRAY[{w_cities}])[1 + n % 4],
       timestamptz '2025-11-01' + n * interval '1 hour'
FROM generate_series(1, 2000) AS n;

-- {w_c_seed}
SELECT setseed(0.42);

-- {w_c_orders}
INSERT INTO orders (customer_id, status, created_at)
SELECT 8 + floor(random() * 2000)::int,
       (ARRAY['paid', 'shipped', 'shipped', 'shipped', 'cancelled'])[1 + floor(random() * 5)::int],
       timestamptz '2025-11-19' + random() * interval '365 days'
FROM generate_series(1, 100000);

-- {w_c_items}
INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT o.id, p.id, 1 + floor(random() * 3)::int, p.price
FROM orders o
CROSS JOIN LATERAL (
  SELECT id, price FROM products ORDER BY random() + o.id * 0 LIMIT 1 + o.id % 3
) AS p;

-- {w_c_known}
INSERT INTO orders (customer_id, status, created_at) VALUES
  (1, 'shipped', '2026-11-02 10:00+00'), (1, 'paid', '2026-11-15 18:30+00'),
  (2, 'shipped', '2026-11-05 09:15+00'), (3, 'cancelled', '2026-11-06 12:00+00'),
  (5, 'pending', '2026-11-18 20:45+00'), (6, 'paid', '2026-11-10 08:00+00');
INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT o.id, x.product_id, x.quantity, p.price
FROM (VALUES (1, 1, 1), (1, 4, 2), (2, 2, 4), (3, 8, 1), (3, 10, 3), (4, 5, 1),
             (5, 12, 1), (6, 1, 2), (6, 11, 1)) AS x (n, product_id, quantity)
JOIN orders o ON o.id = 100000 + x.n
JOIN products p ON p.id = x.product_id;

ANALYZE;
''',
    "node/query.ts": '''import pg from "pg";

const pool = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop" });

// {w_c_bad}
const input = "x' OR '1'='1";

// {w_c_concat}
const unsafe = await pool.query(`SELECT id, email FROM customers WHERE email = '${input}'`);
console.log("{w_d_unsafe}:", unsafe.rowCount, "{w_d_rows}");

// {w_c_param}
const safe = await pool.query("SELECT id, email FROM customers WHERE email = $1", [input]);
console.log("{w_d_safe}:", safe.rowCount, "{w_d_rows}");

const sara = await pool.query(
  "SELECT c.name, count(o.id) AS orders FROM customers c " +
    "LEFT JOIN orders o ON o.customer_id = c.id WHERE c.email = $1 GROUP BY c.name",
  ["sara@example.com"],
);
// {w_c_bigint}
console.log(sara.rows[0], typeof sara.rows[0].orders);

await pool.end();
''',
    "php/query.php": '''<?php

declare(strict_types=1);

$db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, // {w_c_pdo_errors}
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

// {w_c_bad}
$input = "x' OR '1'='1";

// {w_c_concat}
$unsafe = $db->query("SELECT id, email FROM customers WHERE email = '$input'");
echo '{w_d_unsafe}: ', count($unsafe->fetchAll()), " {w_d_rows}\\n";

// {w_c_pdo_param}
$safe = $db->prepare('SELECT id, email FROM customers WHERE email = ?');
$safe->execute([$input]);
echo '{w_d_safe}: ', count($safe->fetchAll()), " {w_d_rows}\\n";

$sara = $db->prepare('SELECT c.name, count(o.id) AS orders FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.id WHERE c.email = ? GROUP BY c.name');
$sara->execute(['sara@example.com']);
var_dump($sara->fetch());
''',
}

# The queries of the chapter, in order: (transcript, note key, statements). Each statement is run on its own.
QUERIES = [
    ("describe", "w_s_describe", [r"\d products"]),
    ("select", "w_s_select", [
        "SELECT name, price, stock\nFROM products\nWHERE price < 10000\nORDER BY price DESC\nLIMIT 3;",
        "SELECT count(*) AS products, sum(stock) AS units, min(price), max(price)\nFROM products;",
    ]),
    ("null", "w_s_null", [
        "SELECT name, city FROM customers WHERE city = NULL;",
        "SELECT name, city FROM customers WHERE city IS NULL;",
        "SELECT NULL = NULL AS equal, NULL IS NULL AS is_null, 1 + NULL AS sum;",
    ]),
    ("rules", "w_s_rules", [
        "INSERT INTO products (name, price) VALUES ('Free sample', 0);",
        "INSERT INTO orders (customer_id) VALUES (999999);",
        "INSERT INTO customers (name, email) VALUES ('Sara 2', 'sara@example.com');",
        "UPDATE products SET stock = stock - 5 WHERE id = 3;",
    ]),
    ("join", "w_s_join", [
        "SELECT c.name, o.id, o.status, sum(i.quantity * i.price) AS total\n"
        "FROM customers c\nJOIN orders o ON o.customer_id = c.id\nJOIN order_items i ON i.order_id = o.id\n"
        "WHERE c.id <= 7\nGROUP BY c.name, o.id, o.status\nORDER BY o.id;",
    ]),
    ("left", "w_s_left", [
        "SELECT c.name, count(o.id) AS orders\nFROM customers c\nLEFT JOIN orders o ON o.customer_id = c.id\n"
        "WHERE c.id <= 7\nGROUP BY c.id, c.name\nORDER BY c.id;",
    ]),
    ("group", "w_s_group", [
        "SELECT p.name, sum(i.quantity) AS units, sum(i.quantity * i.price) / 100 AS revenue\n"
        "FROM order_items i\nJOIN orders o ON o.id = i.order_id\nJOIN products p ON p.id = i.product_id\n"
        "WHERE o.status <> 'cancelled'\nGROUP BY p.name\nHAVING sum(i.quantity) > 26600\n"
        "ORDER BY revenue DESC;",
    ]),
    ("window", "w_s_window", [
        "WITH spent AS (\n  SELECT o.customer_id, sum(i.quantity * i.price) AS total\n  FROM orders o\n"
        "  JOIN order_items i ON i.order_id = o.id\n  WHERE o.status <> 'cancelled'\n  GROUP BY o.customer_id\n)\n"
        "SELECT c.name, s.total,\n       rank() OVER (ORDER BY s.total DESC) AS place,\n"
        "       round(s.total * 100.0 / sum(s.total) OVER (), 1) AS percent\nFROM spent s\n"
        "JOIN customers c ON c.id = s.customer_id\nWHERE c.id <= 7\nORDER BY place;",
    ]),
    ("write", "w_s_write", [
        "INSERT INTO customers (name, email, city)\nVALUES ('Nour', 'nour@example.com', 'Giza')\n"
        "RETURNING id, created_at;",
        "INSERT INTO customers (name, email, city)\nVALUES ('Nour', 'nour@example.com', 'Aswan')\n"
        "ON CONFLICT (email) DO UPDATE SET city = excluded.city\nRETURNING id, name, city;",
        "UPDATE products SET stock = stock + 5\nWHERE id = 3\nRETURNING name, stock;",
    ]),
    ("slow", "w_s_slow", [
        "EXPLAIN (ANALYZE, COSTS OFF, BUFFERS OFF)\nSELECT count(*) FROM orders WHERE customer_id = 1234;",
    ]),
    ("index", "w_s_index", [
        "CREATE INDEX orders_customer_id_idx ON orders (customer_id);",
        "EXPLAIN (ANALYZE, COSTS OFF, BUFFERS OFF)\nSELECT count(*) FROM orders WHERE customer_id = 1234;",
    ]),
    ("expression", "w_s_expr", [
        "EXPLAIN (COSTS OFF)\nSELECT id FROM customers WHERE lower(email) = 'sara@example.com';",
        "CREATE INDEX customers_lower_email_idx ON customers (lower(email));",
        "EXPLAIN (COSTS OFF)\nSELECT id FROM customers WHERE lower(email) = 'sara@example.com';",
    ]),
]

ANSWERS = [
    ("answers", None, [
        # 1
        "SELECT name, email FROM customers\nWHERE city = '{w_cairo}' AND id <= 7\nORDER BY name;",
        # 2
        "SELECT name, city FROM customers\nWHERE id <= 7 AND city IS DISTINCT FROM '{w_cairo}'\nORDER BY id;",
        # 3
        "SELECT p.name, count(i.order_id) AS orders\nFROM products p\n"
        "LEFT JOIN order_items i ON i.product_id = p.id AND i.order_id > 100000\n"
        "GROUP BY p.id, p.name\nHAVING count(i.order_id) = 0\nORDER BY p.id;",
        # 4
        "CREATE INDEX orders_pending_recent_idx ON orders (created_at) WHERE status = 'pending';",
        "EXPLAIN (COSTS OFF)\nSELECT id FROM orders\nWHERE status = 'pending' AND created_at > '2026-11-12';",
        # 5
        "WITH monthly AS (\n  SELECT date_trunc('month', o.created_at AT TIME ZONE 'UTC')::date AS month,\n"
        "         sum(i.quantity * i.price) / 100 AS revenue\n  FROM orders o\n"
        "  JOIN order_items i ON i.order_id = o.id\n  WHERE o.status <> 'cancelled'\n  GROUP BY 1\n)\n"
        "SELECT month, revenue,\n       sum(revenue) OVER (ORDER BY month) AS running_total,\n"
        "       revenue - lag(revenue) OVER (ORDER BY month) AS change\nFROM monthly\n"
        "ORDER BY month\nLIMIT 4;",
    ]),
]


def psql(statement, folder):
    """Runs one statement with psql, as `shop=#` would show it."""
    r = subprocess.run(["psql", "shop", "-c", statement], cwd=folder, env=CLEAN,
                       capture_output=True, text=True, timeout=120)
    lines = statement.split("\n")
    shown = ["shop=# " + lines[0]] + ["shop-# " + line for line in lines[1:]]
    out = (r.stdout + r.stderr).rstrip("\n")
    return shown + ([out] if out else [])


def run_queries(folder, t, groups):
    for name, note, statements in groups:
        lines = [f"# {t[note]}"] if note else []
        for statement in statements:
            lines += psql(fill(statement, t), folder)
        (folder / f"{name}.sh").write_text("\n".join(lines) + "\n")


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.note(t["w_s_load"])
    s.run("psql shop -f schema.sql")
    s.run("psql shop -q -f seed.sql > /dev/null")
    s.run("psql shop -c 'SELECT (SELECT count(*) FROM customers) AS customers, "
          "(SELECT count(*) FROM orders) AS orders, (SELECT count(*) FROM order_items) AS items;'")
    s.save(folder / "load.sh")
    run_queries(folder, t, QUERIES)

    s.note(t["w_s_node"])
    s.run("node node/query.ts")
    s.save(folder / "node.sh")
    s.note(t["w_s_php"])
    s.run("php php/query.php")
    s.save(folder / "php.sh")

    run_queries(folder, t, ANSWERS)


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
