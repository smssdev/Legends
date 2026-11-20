# One step fails, so nothing happens
$ psql shop -a -f atomic.sql 2>&1
BEGIN;
BEGIN
UPDATE products SET stock = stock - 1 WHERE id = 2;
UPDATE 1
UPDATE products SET stock = stock - 100 WHERE id = 1;
psql:atomic.sql:3: ERROR:  new row for relation "products" violates check constraint "products_stock_check"
DETAIL:  Failing row contains (1, Robot kit, 45000, -99).
SELECT name, stock FROM products;
psql:atomic.sql:4: ERROR:  current transaction is aborted, commands ignored until end of transaction block
COMMIT;
ROLLBACK
SELECT name, stock FROM products;
     name     | stock 
--------------+-------
 Robot kit    |     1
 Spare wheels |    10
(2 rows)
