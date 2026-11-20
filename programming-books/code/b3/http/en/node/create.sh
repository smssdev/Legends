# Create a product: 201 Created, and Location says where it lives
$ curl -si -X POST localhost:3000/products -H 'Content-Type: application/json' -d '{"name": "USB cable", "price": 2500}'
HTTP/1.1 201 Created
Content-Type: application/json; charset=utf-8
Content-Length: 40
Location: /products/4
Date: Thu, 19 Nov 2026 18:42:39 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"id":4,"name":"USB cable","price":2500}
# It is there now
$ curl -s localhost:3000/products/4
{"id":4,"name":"USB cable","price":2500}
