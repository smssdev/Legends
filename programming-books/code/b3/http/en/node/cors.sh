# A browser asks first (a preflight) before a POST from another site
$ curl -si -X OPTIONS localhost:3000/products -H 'Origin: http://localhost:5173' -H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: content-type'
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: http://localhost:5173
Vary: Origin
Content-Length: 0
Access-Control-Allow-Methods: GET, POST
Access-Control-Allow-Headers: Content-Type
Access-Control-Max-Age: 600
Date: Thu, 19 Nov 2026 14:47:26 GMT
Connection: keep-alive
Keep-Alive: timeout=5
# Another site is not on the list: no Access-Control header, so the browser blocks it
$ curl -si localhost:3000/products/1 -H 'Origin: https://evil.example'
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 41
Date: Thu, 19 Nov 2026 14:47:26 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"id":1,"name":"Robot kit","price":45000}
