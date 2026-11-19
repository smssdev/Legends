# تصدير يُبث وهو يُصنع: لا Content-Length، بل chunked
$ curl -s -D - localhost:3000/export | head -n 12
HTTP/1.1 200 OK
Content-Type: text/csv; charset=utf-8
Date: Thu, 19 Nov 2026 18:32:02 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

id,customer,total
1,customer-1,7919
2,customer-2,15838
3,customer-3,23757
4,customer-4,31676
