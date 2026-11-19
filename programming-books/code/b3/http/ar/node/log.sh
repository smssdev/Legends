# شغّل الخادم (واتركه يعمل في هذه النافذة)
$ node server.ts
Listening on http://localhost:3000
GET /products/1 200 1ms
GET /products/2 200 0ms
GET /products?max_price=15000 200 1ms
HEAD /products 200 1ms
POST /products 201 2ms
GET /products/4 200 0ms
GET /products/99 404 0ms
DELETE /products 405 1ms
...
