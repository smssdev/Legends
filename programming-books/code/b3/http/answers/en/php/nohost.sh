$ printf 'GET /products/1 HTTP/1.1\r\nConnection: close\r\n\r\n' | nc localhost 8000
HTTP/1.1 200 OK
Date: Thu, 19 Nov 2026 18:42:41 GMT
Connection: close
Vary: Accept-Encoding
Content-Type: application/json; charset=utf-8
Content-Length: 41

{"id":1,"name":"Robot kit","price":45000}
