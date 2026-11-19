# قائمة مصفّاة بنص الاستعلام
$ curl -s 'localhost:3000/products?max_price=15000'
[{"id":2,"name":"عجلات احتياطية","price":6000},{"id":3,"name":"حزمة بطارية","price":12500}]
# الترويسات وحدها (HEAD): الجواب نفسه بلا محتوى
$ curl -sI localhost:3000/products
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 168
ETag: "25b59567250630bf"
Cache-Control: no-cache
Date: Thu, 19 Nov 2026 14:47:28 GMT
Connection: keep-alive
Keep-Alive: timeout=5
