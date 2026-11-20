# How does PostgreSQL find one customer's orders?
shop=# EXPLAIN (ANALYZE, COSTS OFF, BUFFERS OFF)
shop-# SELECT count(*) FROM orders WHERE customer_id = 1234;
                               QUERY PLAN                               
------------------------------------------------------------------------
 Aggregate (actual time=5.177..5.178 rows=1.00 loops=1)
   ->  Seq Scan on orders (actual time=0.067..5.166 rows=44.00 loops=1)
         Filter: (customer_id = 1234)
         Rows Removed by Filter: 99962
 Planning Time: 0.293 ms
 Execution Time: 5.231 ms
(6 rows)
