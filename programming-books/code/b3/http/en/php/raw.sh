# Type a request by hand: HTTP/1.1 is plain text over a TCP connection
$ printf 'GET /products/1 HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' | nc localhost 8000
HTTP/1.1 200 OK
Host: localhost
Date: Thu, 19 Nov 2026 14:47:26 GMT
Connection: close
Content-Type: application/json; charset=utf-8
Content-Length: 41

{"id":1,"name":"Robot kit","price":45000}
