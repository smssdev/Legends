EXPLAIN (ANALYZE, COSTS OFF)
SELECT id, name, price FROM products
WHERE category = 'cables-42'
ORDER BY price
LIMIT 20;
