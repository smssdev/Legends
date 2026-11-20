$ curl -s -D - -o /dev/null localhost:3000/products -H 'Accept-Encoding: gzip'
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Encoding: gzip
Content-Length: 105
Vary: Accept-Encoding
ETag: "ab1f4b69728a1521"
Cache-Control: no-cache
Date: Thu, 19 Nov 2026 18:42:40 GMT
Connection: keep-alive
Keep-Alive: timeout=5
$ curl -s -D - -o /dev/null localhost:3000/products
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 128
Vary: Accept-Encoding
ETag: "ab1f4b69728a1521"
Cache-Control: no-cache
Date: Thu, 19 Nov 2026 18:42:40 GMT
Connection: keep-alive
Keep-Alive: timeout=5
$ curl -s --compressed localhost:3000/products
[{"id":1,"name":"Robot kit","price":45000},{"id":2,"name":"Spare wheels","price":6000},{"id":4,"name":"USB cable","price":2500}]
