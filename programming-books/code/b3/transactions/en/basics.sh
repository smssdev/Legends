# A transaction: all or nothing
$ psql shop -a -f basics.sql 2>&1
BEGIN;
BEGIN
UPDATE products SET stock = stock + 5 WHERE id = 2;
UPDATE 1
SELECT name, stock FROM products WHERE id = 2;
     name     | stock 
--------------+-------
 Spare wheels |    15
(1 row)

ROLLBACK;
ROLLBACK
SELECT name, stock FROM products WHERE id = 2;
     name     | stock 
--------------+-------
 Spare wheels |    10
(1 row)
