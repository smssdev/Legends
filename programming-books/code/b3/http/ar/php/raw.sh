# اكتب طلباً بيدك: HTTP/1.1 نص عادي فوق اتصال TCP
$ printf 'GET /products/1 HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' | nc localhost 8000
HTTP/1.1 200 OK
Host: localhost
Date: Thu, 19 Nov 2026 18:42:42 GMT
Connection: close
Content-Type: application/json; charset=utf-8
Content-Length: 53

{"id":1,"name":"عدة الروبوت","price":45000}
