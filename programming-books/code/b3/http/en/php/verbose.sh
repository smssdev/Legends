# Let curl show both sides: * is curl's own news, > is sent, < is received
$ curl -sv localhost:8000/products/2
* Host localhost:8000 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000
> GET /products/2 HTTP/1.1
> Host: localhost:8000
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< Host: localhost:8000
< Date: Thu, 19 Nov 2026 18:42:39 GMT
< Connection: close
< Content-Type: application/json; charset=utf-8
< Content-Length: 43
< 
{ [43 bytes data]
* Closing connection
{"id":2,"name":"Spare wheels","price":6000}
