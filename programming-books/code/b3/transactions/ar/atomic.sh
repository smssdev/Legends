# خطوة تفشل، فلا يحدث شيء
$ psql shop -a -f atomic.sql 2>&1
BEGIN;
BEGIN
UPDATE products SET stock = stock - 1 WHERE id = 2;
UPDATE 1
UPDATE products SET stock = stock - 100 WHERE id = 1;
SELECT name, stock FROM products;
psql:atomic.sql:3: ERROR:  new row for relation "products" violates check constraint "products_stock_check"
DETAIL:  Failing row contains (1, عدة الروبوت, 45000, -99).
psql:atomic.sql:4: ERROR:  current transaction is aborted, commands ignored until end of transaction block
COMMIT;
ROLLBACK
SELECT name, stock FROM products;
      name      | stock 
----------------+-------
 عدة الروبوت    |     1
 عجلات احتياطية |    10
(2 rows)
