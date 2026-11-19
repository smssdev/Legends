# A list, filtered by a query string
$ curl -s 'localhost:3000/products?max_price=15000'
[{"id":2,"name":"Spare wheels","price":6000},{"id":3,"name":"Battery pack","price":12500}]
# Only the headers (HEAD): the same answer without the body
$ curl -sI localhost:3000/products
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 132
ETag: "8f38510311e374f1"
Cache-Control: no-cache
Date: Thu, 19 Nov 2026 18:42:39 GMT
Connection: keep-alive
Keep-Alive: timeout=5
