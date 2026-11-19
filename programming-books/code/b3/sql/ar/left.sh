# LEFT JOIN تُبقي العملاء الذين لا طلبات لهم
shop=# SELECT c.name, count(o.id) AS orders
shop-# FROM customers c
shop-# LEFT JOIN orders o ON o.customer_id = c.id
shop-# WHERE c.id <= 7
shop-# GROUP BY c.id, c.name
shop-# ORDER BY c.id;
 name | orders 
------+--------
 سارة |      2
 عمر  |      1
 لينا |      1
 كريم |      0
 منى  |      1
 يوسف |      1
 هناء |      0
(7 rows)
