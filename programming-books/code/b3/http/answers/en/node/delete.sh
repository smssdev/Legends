$ curl -s -X DELETE localhost:3000/products/3 -w ' %{http_code}\n'
 204
$ curl -s -X DELETE localhost:3000/products/3 -w ' %{http_code}\n'
{"error":{"code":"not_found","message":"No product with this id"}} 404
$ curl -s localhost:3000/products/3 -w ' %{http_code}\n'
{"error":{"code":"not_found","message":"No product with this id"}} 404
$ curl -s localhost:3000/products -H 'Content-Type: application/json' -d '{"name": "USB cable", "price": 2500}' -w ' %{http_code}\n'
{"id":4,"name":"USB cable","price":2500} 201
