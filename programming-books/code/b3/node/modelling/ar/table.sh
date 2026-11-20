# الجدول بعد الترحيلات الثلاثة
$ psql shop -c '\d products'
                        Table "public.products"
 Column |  Type   | Collation | Nullable |           Default            
--------+---------+-----------+----------+------------------------------
 id     | bigint  |           | not null | generated always as identity
 name   | text    |           | not null | 
 price  | integer |           | not null | 
 stock  | integer |           | not null | 0
 sku    | text    |           | not null | 
Indexes:
    "products_pkey" PRIMARY KEY, btree (id)
    "products_sku_key" UNIQUE, btree (sku)
Check constraints:
    "products_price_check" CHECK (price > 0)
    "products_stock_check" CHECK (stock >= 0)
Referenced by:
    TABLE "order_items" CONSTRAINT "order_items_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id)
# يسجّل Kysely ما عمل، في جدول خاص به
$ psql shop -c 'SELECT name, timestamp FROM kysely_migration ORDER BY name'
                name                 |        timestamp         
-------------------------------------+--------------------------
 2026_11_01_001_initial              | 2026-11-19T21:14:02.169Z
 2026_11_02_001_product_sku_expand   | 2026-11-19T21:14:02.171Z
 2026_11_03_001_product_sku_contract | 2026-11-19T21:14:02.173Z
(3 rows)
