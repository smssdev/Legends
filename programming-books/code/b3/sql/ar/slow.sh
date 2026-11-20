# كيف تجد PostgreSQL طلبات عميل واحد؟
shop=# EXPLAIN (ANALYZE, COSTS OFF, BUFFERS OFF)
shop-# SELECT count(*) FROM orders WHERE customer_id = 1234;
                               QUERY PLAN                               
------------------------------------------------------------------------
 Aggregate (actual time=5.218..5.219 rows=1.00 loops=1)
   ->  Seq Scan on orders (actual time=0.069..5.205 rows=44.00 loops=1)
         Filter: (customer_id = 1234)
         Rows Removed by Filter: 99962
 Planning Time: 0.272 ms
 Execution Time: 5.271 ms
(6 rows)
