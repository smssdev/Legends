# اربط الجداول: طلبات كل عميل مسمّى بإجمالياتها
shop=# SELECT c.name, o.id, o.status, sum(i.quantity * i.price) AS total
shop-# FROM customers c
shop-# JOIN orders o ON o.customer_id = c.id
shop-# JOIN order_items i ON i.order_id = o.id
shop-# WHERE c.id <= 7
shop-# GROUP BY c.name, o.id, o.status
shop-# ORDER BY o.id;
 name |   id   |  status   | total 
------+--------+-----------+-------
 سارة | 100001 | shipped   | 50000
 سارة | 100002 | paid      | 24000
 عمر  | 100003 | shipped   | 42000
 لينا | 100004 | cancelled |  9000
 منى  | 100005 | pending   | 21000
 يوسف | 100006 | paid      | 97500
(6 rows)
