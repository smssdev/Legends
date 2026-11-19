$ curl -s -D - -o /dev/null localhost:8000/products -H 'Accept-Encoding: gzip'
HTTP/1.1 200 OK
Host: localhost:8000
Date: Thu, 19 Nov 2026 18:42:44 GMT
Connection: close
Vary: Accept-Encoding
Content-Encoding: gzip
Content-Type: application/json; charset=utf-8
Content-Length: 126
ETag: "844794d90260b254"
Cache-Control: no-cache
$ curl -s -D - -o /dev/null localhost:8000/products
HTTP/1.1 200 OK
Host: localhost:8000
Date: Thu, 19 Nov 2026 18:42:44 GMT
Connection: close
Vary: Accept-Encoding
Content-Type: application/json; charset=utf-8
Content-Length: 158
ETag: "844794d90260b254"
Cache-Control: no-cache
$ curl -s --compressed localhost:8000/products
[{"id":1,"name":"عدة الروبوت","price":45000},{"id":2,"name":"عجلات احتياطية","price":6000},{"id":4,"name":"كابل USB","price":2500}]
