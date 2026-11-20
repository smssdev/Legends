# An index that matches the query
$ psql shop -c 'CREATE INDEX products_category_price ON products (category, price)'
CREATE INDEX
# The same query plan, with the index
$ psql shop -f query.sql
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 Limit (actual time=0.066..0.185 rows=20.00 loops=1)
   Buffers: shared hit=20 read=3
   ->  Index Scan using products_category_price on products (actual time=0.065..0.182 rows=20.00 loops=1)
         Index Cond: (category = 'cables-42'::text)
         Index Searches: 1
         Buffers: shared hit=20 read=3
 Planning:
   Buffers: shared hit=123 read=1
 Planning Time: 0.450 ms
 Execution Time: 0.209 ms
(10 rows)
