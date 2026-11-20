# A CTE and a window function: rank the named customers by what they spent
shop=# WITH spent AS (
shop-#   SELECT o.customer_id, sum(i.quantity * i.price) AS total
shop-#   FROM orders o
shop-#   JOIN order_items i ON i.order_id = o.id
shop-#   WHERE o.status <> 'cancelled'
shop-#   GROUP BY o.customer_id
shop-# )
shop-# SELECT c.name, s.total,
shop-#        rank() OVER (ORDER BY s.total DESC) AS place,
shop-#        round(s.total * 100.0 / sum(s.total) OVER (), 1) AS percent
shop-# FROM spent s
shop-# JOIN customers c ON c.id = s.customer_id
shop-# WHERE c.id <= 7
shop-# ORDER BY place;
  name   | total | place | percent 
---------+-------+-------+---------
 Youssef | 97500 |     1 |    41.6
 Sara    | 74000 |     2 |    31.6
 Omar    | 42000 |     3 |    17.9
 Mona    | 21000 |     4 |     9.0
(4 rows)
