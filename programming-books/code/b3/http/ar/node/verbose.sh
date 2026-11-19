# اجعل curl يُظهر الجهتين: * أخبار curl نفسه، و> ما يُرسَل، و< ما يصل
$ curl -sv localhost:3000/products/2
* Host localhost:3000 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying 127.0.0.1:3000...
* Connected to localhost (127.0.0.1) port 3000
> GET /products/2 HTTP/1.1
> Host: localhost:3000
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< Content-Type: application/json; charset=utf-8
< Content-Length: 58
< Date: Thu, 19 Nov 2026 18:42:41 GMT
< Connection: keep-alive
< Keep-Alive: timeout=5
< 
{ [58 bytes data]
* Connection #0 to host localhost left intact
{"id":2,"name":"عجلات احتياطية","price":6000}
