# طلب من موقع المتجر
$ curl -s -I localhost:3000/files/terms.txt -H 'Origin: https://shop.example' | grep -i '^HTTP\|^access-control\|^vary'
HTTP/1.1 200 OK
vary: Origin
access-control-allow-origin: https://shop.example
# طلب من موقع آخر
$ curl -s -I localhost:3000/files/terms.txt -H 'Origin: https://evil.example' | grep -i '^HTTP\|^access-control\|^vary'
HTTP/1.1 200 OK
vary: Origin
