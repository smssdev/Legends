# طلب من موقع المتجر
$ curl -s -I localhost:8000/api/files/terms.txt -H 'Origin: https://shop.example' | grep -iE '^(HTTP|access-control|vary)'
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://shop.example
# طلب من موقع آخر
$ curl -s -I localhost:8000/api/files/terms.txt -H 'Origin: https://evil.example' | grep -iE '^(HTTP|access-control|vary)'
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://shop.example
