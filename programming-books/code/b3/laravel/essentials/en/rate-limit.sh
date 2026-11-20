# A server limited to 3 requests a minute (SHOP_RATE_LIMIT=3)
$ for i in 1 2 3; do curl -s -o /dev/null -w '%{http_code} ' localhost:8000/api/products; done; echo
200 200 200 
$ curl -s -D - -o /dev/null localhost:8000/api/products | grep -iE '^(HTTP|x-ratelimit|retry-after)'
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 3
X-RateLimit-Remaining: 0
Retry-After: 60
X-RateLimit-Reset: 1795119416
$ curl -s localhost:8000/api/products
{
    "message": "Too Many Attempts."
}
