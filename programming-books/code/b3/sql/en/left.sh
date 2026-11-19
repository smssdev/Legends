# LEFT JOIN keeps customers without orders
shop=# SELECT c.name, count(o.id) AS orders
shop-# FROM customers c
shop-# LEFT JOIN orders o ON o.customer_id = c.id
shop-# WHERE c.id <= 7
shop-# GROUP BY c.id, c.name
shop-# ORDER BY c.id;
  name   | orders 
---------+--------
 Sara    |      2
 Omar    |      1
 Lina    |      1
 Karim   |      0
 Mona    |      1
 Youssef |      1
 Hana    |      0
(7 rows)
