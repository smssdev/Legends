# psql describes a table: columns, types, defaults, indexes and rules
shop=# \d products
                        Table "public.products"
 Column |  Type   | Collation | Nullable |           Default            
--------+---------+-----------+----------+------------------------------
 id     | bigint  |           | not null | generated always as identity
 name   | text    |           | not null | 
 price  | integer |           | not null | 
 stock  | integer |           | not null | 0
Indexes:
    "products_pkey" PRIMARY KEY, btree (id)
Check constraints:
    "products_price_check" CHECK (price > 0)
    "products_stock_check" CHECK (stock >= 0)
Referenced by:
    TABLE "order_items" CONSTRAINT "order_items_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id)
