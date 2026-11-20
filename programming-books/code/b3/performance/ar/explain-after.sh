# فهرس يطابق الاستعلام
$ psql shop -c 'CREATE INDEX products_category_price ON products (category, price)'
CREATE INDEX
# خطة الاستعلام نفسها، بالفهرس
$ psql shop -f query.sql
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 Limit (actual time=0.135..0.406 rows=20.00 loops=1)
   Buffers: shared hit=20 read=3
   ->  Index Scan using products_category_price on products (actual time=0.132..0.398 rows=20.00 loops=1)
         Index Cond: (category = 'cables-42'::text)
         Index Searches: 1
         Buffers: shared hit=20 read=3
 Planning:
   Buffers: shared hit=123 read=1
 Planning Time: 1.016 ms
 Execution Time: 0.469 ms
(10 rows)
