shop=# SELECT name, email FROM customers
shop-# WHERE city = 'القاهرة' AND id <= 7
shop-# ORDER BY name;
 name |        email        
------+---------------------
 سارة | sara@example.com
 لينا | lina@example.com
 يوسف | youssef@example.com
(3 rows)
shop=# SELECT name, city FROM customers
shop-# WHERE id <= 7 AND city IS DISTINCT FROM 'القاهرة'
shop-# ORDER BY id;
 name |    city    
------+------------
 عمر  | الإسكندرية
 كريم | 
 منى  | الجيزة
 هناء | الإسكندرية
(4 rows)
shop=# SELECT p.name, count(i.order_id) AS orders
shop-# FROM products p
shop-# LEFT JOIN order_items i ON i.product_id = p.id AND i.order_id > 100000
shop-# GROUP BY p.id, p.name
shop-# HAVING count(i.order_id) = 0
shop-# ORDER BY p.id;
    name     | orders 
-------------+--------
 حزمة بطارية |      0
 طقم حساسات  |      0
 جهاز تحكم   |      0
 صندوق تروس  |      0
(4 rows)
shop=# CREATE INDEX orders_pending_recent_idx ON orders (created_at) WHERE status = 'pending';
CREATE INDEX
shop=# EXPLAIN (COSTS OFF)
shop-# SELECT id FROM orders
shop-# WHERE status = 'pending' AND created_at > '2026-11-12';
                                   QUERY PLAN                                    
---------------------------------------------------------------------------------
 Index Scan using orders_pending_recent_idx on orders
   Index Cond: (created_at > '2026-11-12 00:00:00+00'::timestamp with time zone)
(2 rows)
shop=# WITH monthly AS (
shop-#   SELECT date_trunc('month', o.created_at AT TIME ZONE 'UTC')::date AS month,
shop-#          sum(i.quantity * i.price) / 100 AS revenue
shop-#   FROM orders o
shop-#   JOIN order_items i ON i.order_id = o.id
shop-#   WHERE o.status <> 'cancelled'
shop-#   GROUP BY 1
shop-# )
shop-# SELECT month, revenue,
shop-#        sum(revenue) OVER (ORDER BY month) AS running_total,
shop-#        revenue - lag(revenue) OVER (ORDER BY month) AS change
shop-# FROM monthly
shop-# ORDER BY month
shop-# LIMIT 4;
   month    | revenue | running_total | change  
------------+---------+---------------+---------
 2025-11-01 | 1404575 |       1404575 |        
 2025-12-01 | 3860275 |       5264850 | 2455700
 2026-01-01 | 3839800 |       9104650 |  -20475
 2026-02-01 | 3436940 |      12541590 | -402860
(4 rows)
