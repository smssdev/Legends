$ printf 'GET /products/1 HTTP/1.1\r\nConnection: close\r\n\r\n' | nc localhost 8000
HTTP/1.1 200 OK
Date: Thu, 19 Nov 2026 14:47:31 GMT
Connection: close
Vary: Accept-Encoding
Content-Type: application/json; charset=utf-8
Content-Length: 53

{"id":1,"name":"عدة الروبوت","price":45000}
