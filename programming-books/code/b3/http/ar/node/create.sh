# أنشئ منتجاً: 201 Created، وLocation يقول أين يعيش
$ curl -si -X POST localhost:3000/products -H 'Content-Type: application/json' -d '{"name": "كابل USB", "price": 2500}'
HTTP/1.1 201 Created
Content-Type: application/json; charset=utf-8
Content-Length: 43
Location: /products/4
Date: Thu, 19 Nov 2026 14:47:28 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"id":4,"name":"كابل USB","price":2500}
# صار موجوداً الآن
$ curl -s localhost:3000/products/4
{"id":4,"name":"كابل USB","price":2500}
