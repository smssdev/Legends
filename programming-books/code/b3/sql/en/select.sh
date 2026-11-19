# Choose rows and columns, sort, keep the first few
shop=# SELECT name, price, stock
shop-# FROM products
shop-# WHERE price < 10000
shop-# ORDER BY price DESC
shop-# LIMIT 3;
      name      | price | stock 
----------------+-------+-------
 Servo motor    |  9000 |    14
 Remote control |  8000 |     9
 Speaker        |  7500 |    18
(3 rows)
shop=# SELECT count(*) AS products, sum(stock) AS units, min(price), max(price)
shop-# FROM products;
 products | units | min  |  max  
----------+-------+------+-------
       12 |   222 | 2500 | 45000
(1 row)
