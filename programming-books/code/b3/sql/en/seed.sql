INSERT INTO products (name, price, stock) VALUES
  ('Robot kit', 45000, 10), ('Spare wheels', 6000, 25), ('Battery pack', 12500, 0), ('USB cable', 2500, 80), ('Servo motor', 9000, 14), ('Sensor set', 15000, 6), ('Remote control', 8000, 9), ('Solar panel', 30000, 3), ('Gear box', 11000, 12), ('LED strip', 4000, 40), ('Speaker', 7500, 18), ('Camera module', 21000, 5);

-- Seven customers by name, and two thousand more for the performance examples.
INSERT INTO customers (name, email, city) VALUES
  ('Sara', 'sara@example.com', 'Cairo'), ('Omar', 'omar@example.com', 'Alexandria'), ('Lina', 'lina@example.com', 'Cairo'), ('Karim', 'karim@example.com', NULL), ('Mona', 'mona@example.com', 'Giza'), ('Youssef', 'youssef@example.com', 'Cairo'), ('Hana', 'hana@example.com', 'Alexandria');
INSERT INTO customers (name, email, city, created_at)
SELECT 'customer-' || n, 'customer' || n || '@example.com',
       (ARRAY['Cairo', 'Alexandria', 'Giza', 'Aswan'])[1 + n % 4],
       timestamptz '2025-11-01' + n * interval '1 hour'
FROM generate_series(1, 2000) AS n;

-- The same random numbers on every run, so the book's numbers stay the same.
SELECT setseed(0.42);

-- A hundred thousand orders over the last year, from the generated customers.
INSERT INTO orders (customer_id, status, created_at)
SELECT 8 + floor(random() * 2000)::int,
       (ARRAY['paid', 'shipped', 'shipped', 'shipped', 'cancelled'])[1 + floor(random() * 5)::int],
       timestamptz '2025-11-19' + random() * interval '365 days'
FROM generate_series(1, 100000);

-- One to three different products per order.
INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT o.id, p.id, 1 + floor(random() * 3)::int, p.price
FROM orders o
CROSS JOIN LATERAL (
  SELECT id, price FROM products ORDER BY random() + o.id * 0 LIMIT 1 + o.id % 3
) AS p;

-- A few orders for the named customers, to read in the examples.
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
