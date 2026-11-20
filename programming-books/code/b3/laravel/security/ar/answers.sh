# ما يسأله المتصفح قبل PATCH من موقع المتجر
$ curl -s -i -X OPTIONS localhost:8000/api/users/2 -H 'Origin: https://shop.example' -H 'Access-Control-Request-Method: PATCH' -H 'Access-Control-Request-Headers: content-type' | grep -iE '^(HTTP|access-control)'
HTTP/1.0 204 No Content
Access-Control-Allow-Origin: https://shop.example
Access-Control-Allow-Methods: GET, PATCH
Access-Control-Allow-Headers: content-type
Access-Control-Max-Age: 0
