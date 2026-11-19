$ curl -s -X DELETE localhost:8000/products/3 -w ' %{http_code}\n'
 204
$ curl -s -X DELETE localhost:8000/products/3 -w ' %{http_code}\n'
{"error":{"code":"not_found","message":"لا يوجد منتج بهذا الرقم"}} 404
$ curl -s localhost:8000/products/3 -w ' %{http_code}\n'
{"error":{"code":"not_found","message":"لا يوجد منتج بهذا الرقم"}} 404
$ curl -s localhost:8000/products -H 'Content-Type: application/json' -d '{"name": "كابل USB", "price": 2500}' -w ' %{http_code}\n'
{"id":4,"name":"كابل USB","price":2500} 201
