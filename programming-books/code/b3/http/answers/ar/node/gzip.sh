$ curl -s -D - -o /dev/null localhost:3000/products -H 'Accept-Encoding: gzip'
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Encoding: gzip
Content-Length: 137
Vary: Accept-Encoding
ETag: "844794d90260b254"
Cache-Control: no-cache
Date: Thu, 19 Nov 2026 14:47:30 GMT
Connection: keep-alive
Keep-Alive: timeout=5
$ curl -s -D - -o /dev/null localhost:3000/products
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 158
Vary: Accept-Encoding
ETag: "844794d90260b254"
Cache-Control: no-cache
Date: Thu, 19 Nov 2026 14:47:30 GMT
Connection: keep-alive
Keep-Alive: timeout=5
$ curl -s --compressed localhost:3000/products
[{"id":1,"name":"عدة الروبوت","price":45000},{"id":2,"name":"عجلات احتياطية","price":6000},{"id":4,"name":"كابل USB","price":2500}]
