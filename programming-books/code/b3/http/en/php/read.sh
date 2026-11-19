# A list, filtered by a query string
$ curl -s 'localhost:8000/products?max_price=15000'
[{"id":2,"name":"Spare wheels","price":6000},{"id":3,"name":"Battery pack","price":12500}]
# Only the headers (HEAD): the same answer without the body
$ curl -sI localhost:8000/products
HTTP/1.1 200 OK
Host: localhost:8000
Date: Thu, 19 Nov 2026 14:47:26 GMT
Connection: close
Content-Type: application/json; charset=utf-8
Content-Length: 132
ETag: "8f38510311e374f1"
Cache-Control: no-cache
