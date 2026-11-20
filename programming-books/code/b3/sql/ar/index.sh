# أضف فهرساً على المفتاح الأجنبي، واسأل مرة أخرى
shop=# CREATE INDEX orders_customer_id_idx ON orders (customer_id);
CREATE INDEX
shop=# EXPLAIN (ANALYZE, COSTS OFF, BUFFERS OFF)
shop-# SELECT count(*) FROM orders WHERE customer_id = 1234;
                                              QUERY PLAN                                               
-------------------------------------------------------------------------------------------------------
 Aggregate (actual time=0.235..0.236 rows=1.00 loops=1)
   ->  Bitmap Heap Scan on orders (actual time=0.054..0.226 rows=44.00 loops=1)
         Recheck Cond: (customer_id = 1234)
         Heap Blocks: exact=44
         ->  Bitmap Index Scan on orders_customer_id_idx (actual time=0.039..0.039 rows=44.00 loops=1)
               Index Cond: (customer_id = 1234)
               Index Searches: 1
 Planning Time: 0.401 ms
 Execution Time: 0.292 ms
(9 rows)
