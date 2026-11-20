# The first visit: the server sends the list and its ETag
$ curl -si localhost:8000/products
HTTP/1.1 200 OK
Host: localhost:8000
Date: Thu, 19 Nov 2026 18:42:40 GMT
Connection: close
Content-Type: application/json; charset=utf-8
Content-Length: 173
ETag: "c25b00ae213de631"
Cache-Control: no-cache

[{"id":1,"name":"Robot kit","price":45000},{"id":2,"name":"Spare wheels","price":6000},{"id":3,"name":"Battery pack","price":12500},{"id":4,"name":"USB cable","price":2500}]
# The next visit sends the ETag back: nothing changed, so 304 and no body
$ curl -si localhost:8000/products -H 'If-None-Match: "c25b00ae213de631"'
HTTP/1.1 304 Not Modified
Host: localhost:8000
Date: Thu, 19 Nov 2026 18:42:40 GMT
Connection: close
Content-Type:
Content-Length: 0
ETag: "c25b00ae213de631"
