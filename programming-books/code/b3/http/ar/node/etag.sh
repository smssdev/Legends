# الزيارة الأولى: يرسل الخادم القائمة ووسمها ETag
$ curl -si localhost:3000/products
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 212
ETag: "82bbd06582b2c190"
Cache-Control: no-cache
Date: Thu, 19 Nov 2026 18:42:42 GMT
Connection: keep-alive
Keep-Alive: timeout=5

[{"id":1,"name":"عدة الروبوت","price":45000},{"id":2,"name":"عجلات احتياطية","price":6000},{"id":3,"name":"حزمة بطارية","price":12500},{"id":4,"name":"كابل USB","price":2500}]
# الزيارة التالية تعيد الوسم: لم يتغير شيء، فالجواب 304 بلا محتوى
$ curl -si localhost:3000/products -H 'If-None-Match: "82bbd06582b2c190"'
HTTP/1.1 304 Not Modified
Content-Length: 0
ETag: "82bbd06582b2c190"
Date: Thu, 19 Nov 2026 18:42:42 GMT
Connection: keep-alive
Keep-Alive: timeout=5
