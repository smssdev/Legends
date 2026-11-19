# The same report two ways: count the queries
$ SHOP_STRICT=false php artisan shop:report lazy
lazy  200 orders, 201 queries, 166 ms
$ SHOP_STRICT=false php artisan shop:report eager
eager 200 orders, 2 queries, 55 ms
