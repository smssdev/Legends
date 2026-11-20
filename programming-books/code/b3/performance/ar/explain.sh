# خطة الاستعلام، بلا فهرس
$ psql shop -f query.sql
                                           QUERY PLAN                                            
-------------------------------------------------------------------------------------------------
 Limit (actual time=21.074..25.353 rows=20.00 loops=1)
   Buffers: shared hit=4170
   ->  Sort (actual time=21.071..25.347 rows=20.00 loops=1)
         Sort Key: price
         Sort Method: top-N heapsort  Memory: 27kB
         Buffers: shared hit=4170
         ->  Gather (actual time=0.617..25.086 rows=500.00 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               Buffers: shared hit=4167
               ->  Parallel Seq Scan on products (actual time=0.058..16.213 rows=166.67 loops=3)
                     Filter: (category = 'cables-42'::text)
                     Rows Removed by Filter: 166500
                     Buffers: shared hit=4167
 Planning:
   Buffers: shared hit=86 read=4
 Planning Time: 0.847 ms
 Execution Time: 25.410 ms
(18 rows)
