# المنتجات التي تجلب أكثر المال
shop=# SELECT p.name, sum(i.quantity) AS units, sum(i.quantity * i.price) / 100 AS revenue
shop-# FROM order_items i
shop-# JOIN orders o ON o.id = i.order_id
shop-# JOIN products p ON p.id = i.product_id
shop-# WHERE o.status <> 'cancelled'
shop-# GROUP BY p.name
shop-# HAVING sum(i.quantity) > 26600
shop-# ORDER BY revenue DESC;
    name     | units | revenue 
-------------+-------+---------
 حزمة بطارية | 26878 | 3359750
 صندوق تروس  | 26694 | 2936340
 جهاز تحكم   | 26673 | 2133840
 سماعة       | 26676 | 2000700
 شريط LED    | 27350 | 1094000
 كابل USB    | 26699 |  667475
(6 rows)
