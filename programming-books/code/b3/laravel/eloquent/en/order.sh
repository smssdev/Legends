# An order with its customer and products, and the queries behind it
$ php artisan shop:order 2
#2 Sara · On its way · 63500
  1 × Robot kit (45000)
  1 × Spare wheels (6000)
  1 × Battery pack (12500)
SQL: select * from "orders" where "orders"."id" = ? limit 1
SQL: select * from "customers" where "customers"."id" in (1)
SQL: select "products".*, "order_items"."order_id" as "pivot_order_id", "order_items"."product_id" as "pivot_product_id", "order_items"."quantity" as "pivot_quantity", "order_items"."price" as "pivot_price" from "products" inner join "order_items" on "products"."id" = "order_items"."product_id" where "order_items"."order_id" in (2)
