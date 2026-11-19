# Let curl show both sides: * is curl's own news, > is sent, < is received
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
< Content-Length: 43
< Date: Thu, 19 Nov 2026 14:47:25 GMT
< Connection: keep-alive
< Keep-Alive: timeout=5
< 
{ [43 bytes data]
* Connection #0 to host localhost left intact
{"id":2,"name":"Spare wheels","price":6000}
