$ printf 'GET /products/1 HTTP/1.1\r\nConnection: close\r\n\r\n' | nc localhost 3000
HTTP/1.1 400 Bad Request
Connection: close
Date: Thu, 19 Nov 2026 18:42:43 GMT
Transfer-Encoding: chunked

0
