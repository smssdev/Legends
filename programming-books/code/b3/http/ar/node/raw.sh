# اكتب طلباً بيدك: HTTP/1.1 نص عادي فوق اتصال TCP
$ printf 'GET /products/1 HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' | nc localhost 3000
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 53
Date: Thu, 19 Nov 2026 14:47:28 GMT
Connection: close

{"id":1,"name":"عدة الروبوت","price":45000}
