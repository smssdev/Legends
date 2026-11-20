# The query plan, without an index
$ psql shop -f query.sql
                                           QUERY PLAN                                            
-------------------------------------------------------------------------------------------------
 Limit (actual time=20.416..28.366 rows=20.00 loops=1)
   Buffers: shared hit=4170
   ->  Sort (actual time=20.413..28.360 rows=20.00 loops=1)
         Sort Key: price
         Sort Method: top-N heapsort  Memory: 27kB
         Buffers: shared hit=4170
         ->  Gather (actual time=0.333..28.204 rows=500.00 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               Buffers: shared hit=4167
               ->  Parallel Seq Scan on products (actual time=0.036..17.474 rows=166.67 loops=3)
                     Filter: (category = 'cables-42'::text)
                     Rows Removed by Filter: 166500
                     Buffers: shared hit=4167
 Planning:
   Buffers: shared hit=86 read=4
 Planning Time: 0.412 ms
 Execution Time: 28.420 ms
(18 rows)
