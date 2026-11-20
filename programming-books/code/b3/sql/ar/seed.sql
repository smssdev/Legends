INSERT INTO products (name, price, stock) VALUES
  ('عدة الروبوت', 45000, 10), ('عجلات احتياطية', 6000, 25), ('حزمة بطارية', 12500, 0), ('كابل USB', 2500, 80), ('محرك سيرفو', 9000, 14), ('طقم حساسات', 15000, 6), ('جهاز تحكم', 8000, 9), ('لوح شمسي', 30000, 3), ('صندوق تروس', 11000, 12), ('شريط LED', 4000, 40), ('سماعة', 7500, 18), ('وحدة كاميرا', 21000, 5);

-- سبعة عملاء بأسمائهم، وألفان آخرون لأمثلة الأداء.
INSERT INTO customers (name, email, city) VALUES
  ('سارة', 'sara@example.com', 'القاهرة'), ('عمر', 'omar@example.com', 'الإسكندرية'), ('لينا', 'lina@example.com', 'القاهرة'), ('كريم', 'karim@example.com', NULL), ('منى', 'mona@example.com', 'الجيزة'), ('يوسف', 'youssef@example.com', 'القاهرة'), ('هناء', 'hana@example.com', 'الإسكندرية');
INSERT INTO customers (name, email, city, created_at)
SELECT 'customer-' || n, 'customer' || n || '@example.com',
       (ARRAY['القاهرة', 'الإسكندرية', 'الجيزة', 'أسوان'])[1 + n % 4],
       timestamptz '2025-11-01' + n * interval '1 hour'
FROM generate_series(1, 2000) AS n;

-- الأعداد العشوائية نفسها في كل تشغيل، فتبقى أرقام الكتاب كما هي.
SELECT setseed(0.42);

-- مئة ألف طلب في السنة الماضية، من العملاء المولَّدين.
INSERT INTO orders (customer_id, status, created_at)
SELECT 8 + floor(random() * 2000)::int,
       (ARRAY['paid', 'shipped', 'shipped', 'shipped', 'cancelled'])[1 + floor(random() * 5)::int],
       timestamptz '2025-11-19' + random() * interval '365 days'
FROM generate_series(1, 100000);

-- من منتج إلى ثلاثة منتجات مختلفة في كل طلب.
INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT o.id, p.id, 1 + floor(random() * 3)::int, p.price
FROM orders o
CROSS JOIN LATERAL (
  SELECT id, price FROM products ORDER BY random() + o.id * 0 LIMIT 1 + o.id % 3
) AS p;

-- طلبات قليلة للعملاء المسمّين، لنقرأها في الأمثلة.
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
