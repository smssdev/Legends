BEGIN;
UPDATE products SET stock = stock + 5 WHERE id = 2;
SELECT name, stock FROM products WHERE id = 2;
ROLLBACK;
SELECT name, stock FROM products WHERE id = 2;
