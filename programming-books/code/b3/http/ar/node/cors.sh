# المتصفح يسأل أولاً (طلب تمهيدي) قبل POST من موقع آخر
$ curl -si -X OPTIONS localhost:3000/products -H 'Origin: http://localhost:5173' -H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: content-type'
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: http://localhost:5173
Vary: Origin
Content-Length: 0
Access-Control-Allow-Methods: GET, POST
Access-Control-Allow-Headers: Content-Type
Access-Control-Max-Age: 600
Date: Thu, 19 Nov 2026 18:42:42 GMT
Connection: keep-alive
Keep-Alive: timeout=5
# موقع آخر ليس في القائمة: لا ترويسة Access-Control، فيمنعه المتصفح
$ curl -si localhost:3000/products/1 -H 'Origin: https://evil.example'
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 53
Date: Thu, 19 Nov 2026 18:42:42 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"id":1,"name":"عدة الروبوت","price":45000}
