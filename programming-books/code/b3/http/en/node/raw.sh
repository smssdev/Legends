# Type a request by hand: HTTP/1.1 is plain text over a TCP connection
$ printf 'GET /products/1 HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' | nc localhost 3000
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 41
Date: Thu, 19 Nov 2026 14:47:25 GMT
Connection: close

{"id":1,"name":"Robot kit","price":45000}
