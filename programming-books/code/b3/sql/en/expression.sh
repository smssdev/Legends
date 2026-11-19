# An index on an expression, for case-insensitive email lookups
shop=# EXPLAIN (COSTS OFF)
shop-# SELECT id FROM customers WHERE lower(email) = 'sara@example.com';
                     QUERY PLAN                      
-----------------------------------------------------
 Seq Scan on customers
   Filter: (lower(email) = 'sara@example.com'::text)
(2 rows)
shop=# CREATE INDEX customers_lower_email_idx ON customers (lower(email));
CREATE INDEX
shop=# EXPLAIN (COSTS OFF)
shop-# SELECT id FROM customers WHERE lower(email) = 'sara@example.com';
                          QUERY PLAN                           
---------------------------------------------------------------
 Bitmap Heap Scan on customers
   Recheck Cond: (lower(email) = 'sara@example.com'::text)
   ->  Bitmap Index Scan on customers_lower_email_idx
         Index Cond: (lower(email) = 'sara@example.com'::text)
(4 rows)
