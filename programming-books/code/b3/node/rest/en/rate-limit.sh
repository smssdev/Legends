# A server limited to 3 requests a minute (RATE_LIMIT=3)
$ for i in 1 2 3; do curl -s -o /dev/null -w '%{http_code} ' localhost:3000/v1/products/1; done; echo
200 200 200 
$ curl -si localhost:3000/v1/products/1 | grep -iE '^(HTTP|x-ratelimit|retry-after)|^\{'
HTTP/1.1 429 Too Many Requests
x-ratelimit-limit: 3
x-ratelimit-remaining: 0
x-ratelimit-reset: 60
retry-after: 60
{"type":"https://bit-shop.example/problems/too-many-requests","title":"Too many requests","status":429,"detail":"Try again in 60 seconds.","instance":"/v1/products/1"}
