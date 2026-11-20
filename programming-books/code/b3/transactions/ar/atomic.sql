BEGIN;
UPDATE products SET stock = stock - 1 WHERE id = 2;
UPDATE products SET stock = stock - 100 WHERE id = 1;
SELECT name, stock FROM products;
COMMIT;
SELECT name, stock FROM products;
