# An order
$ curl -s localhost:8000/api/orders -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"sara@example.com","items":[{"product_id":1,"quantity":2},{"product_id":2,"quantity":4}]}' | jq -c
{"id":1,"total":114000}
# Eleven of one product
$ curl -s localhost:8000/api/orders -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"sara@example.com","items":[{"product_id":2,"quantity":11}]}' | jq -c
{"title":"At most 10 of one product per order","status":422}
# More than the stock
$ curl -s localhost:8000/api/orders -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"sara@example.com","items":[{"product_id":1,"quantity":4}]}' | jq -c
{"title":"Not enough stock","status":409}
$ psql shop -c 'SELECT id, stock FROM products ORDER BY id'
 id | stock 
----+-------
  1 |     3
  2 |    46
(2 rows)
$ grep -o 'mail to.*' storage/logs/laravel.log
mail to sara@example.com: Order 1: 1140 EGP  
