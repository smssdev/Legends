# أنشئ منتجاً: 201 Created، وLocation يقول أين يعيش
$ curl -si -X POST localhost:8000/products -H 'Content-Type: application/json' -d '{"name": "كابل USB", "price": 2500}'
HTTP/1.1 201 Created
Host: localhost:8000
Date: Thu, 19 Nov 2026 18:42:42 GMT
Connection: close
Content-Type: application/json; charset=utf-8
Content-Length: 43
Location: /products/4

{"id":4,"name":"كابل USB","price":2500}
# صار موجوداً الآن
$ curl -s localhost:8000/products/4
{"id":4,"name":"كابل USB","price":2500}
