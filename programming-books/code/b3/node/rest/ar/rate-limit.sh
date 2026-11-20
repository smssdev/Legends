# خادم محدود بثلاثة طلبات في الدقيقة (RATE_LIMIT=3)
$ for i in 1 2 3; do curl -s -o /dev/null -w '%{http_code} ' localhost:3000/v1/products/1; done; echo
200 200 200 
$ curl -si localhost:3000/v1/products/1 | grep -iE '^(HTTP|x-ratelimit|retry-after)|^\{'
HTTP/1.1 429 Too Many Requests
x-ratelimit-limit: 3
x-ratelimit-remaining: 0
x-ratelimit-reset: 60
retry-after: 60
{"type":"https://bit-shop.example/problems/too-many-requests","title":"طلبات كثيرة جداً","status":429,"detail":"حاول مرة أخرى بعد 60 ثانية.","instance":"/v1/products/1"}
