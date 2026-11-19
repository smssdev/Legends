$ curl -s -D - -o /dev/null localhost:8000/products -H 'Accept-Encoding: gzip'
HTTP/1.1 200 OK
Host: localhost:8000
Date: Thu, 19 Nov 2026 14:47:28 GMT
Connection: close
Vary: Accept-Encoding
Content-Encoding: gzip
Content-Type: application/json; charset=utf-8
Content-Length: 103
ETag: "ab1f4b69728a1521"
Cache-Control: no-cache
$ curl -s -D - -o /dev/null localhost:8000/products
HTTP/1.1 200 OK
Host: localhost:8000
Date: Thu, 19 Nov 2026 14:47:28 GMT
Connection: close
Vary: Accept-Encoding
Content-Type: application/json; charset=utf-8
Content-Length: 128
ETag: "ab1f4b69728a1521"
Cache-Control: no-cache
$ curl -s --compressed localhost:8000/products
[{"id":1,"name":"Robot kit","price":45000},{"id":2,"name":"Spare wheels","price":6000},{"id":4,"name":"USB cable","price":2500}]
