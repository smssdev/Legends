# المتصفح يسأل أولاً (طلب تمهيدي) قبل POST من موقع آخر
$ curl -si -X OPTIONS localhost:8000/products -H 'Origin: http://localhost:5173' -H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: content-type'
HTTP/1.1 204 No Content
Host: localhost:8000
Date: Thu, 19 Nov 2026 14:47:29 GMT
Connection: close
Access-Control-Allow-Origin: http://localhost:5173
Vary: Origin
Content-Type:
Content-Length: 0
Access-Control-Allow-Methods: GET, POST
Access-Control-Allow-Headers: Content-Type
Access-Control-Max-Age: 600
# موقع آخر ليس في القائمة: لا ترويسة Access-Control، فيمنعه المتصفح
$ curl -si localhost:8000/products/1 -H 'Origin: https://evil.example'
HTTP/1.1 200 OK
Host: localhost:8000
Date: Thu, 19 Nov 2026 14:47:29 GMT
Connection: close
Content-Type: application/json; charset=utf-8
Content-Length: 53

{"id":1,"name":"عدة الروبوت","price":45000}
