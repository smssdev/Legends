# What a browser asks before a PATCH from the shop's website
$ curl -s -i -X OPTIONS localhost:3000/users/2 -H 'Origin: https://shop.example' -H 'Access-Control-Request-Method: PATCH' -H 'Access-Control-Request-Headers: content-type' | grep -i '^HTTP\|^access-control'
HTTP/1.1 204 No Content
access-control-allow-origin: https://shop.example
access-control-allow-methods: GET, PATCH
access-control-allow-headers: content-type
