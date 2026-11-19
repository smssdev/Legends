# شغّل الخادم (واتركه يعمل في هذه النافذة)
$ php -S localhost:8000 server.php
[Thu Nov 19 18:42:42 2026] PHP 8.5.13 Development Server (http://localhost:8000) started
[Thu Nov 19 18:42:42 2026] 127.0.0.1:47754 Accepted
[Thu Nov 19 18:42:42 2026] GET /products/1 200 0ms
[Thu Nov 19 18:42:42 2026] 127.0.0.1:47754 Closing
[Thu Nov 19 18:42:42 2026] 127.0.0.1:47768 Accepted
[Thu Nov 19 18:42:42 2026] GET /products/2 200 0ms
[Thu Nov 19 18:42:42 2026] 127.0.0.1:47768 Closing
[Thu Nov 19 18:42:42 2026] 127.0.0.1:47774 Accepted
[Thu Nov 19 18:42:42 2026] GET /products?max_price=15000 200 0ms
[Thu Nov 19 18:42:42 2026] 127.0.0.1:47774 Closing
[Thu Nov 19 18:42:42 2026] 127.0.0.1:47790 Accepted
[Thu Nov 19 18:42:42 2026] HEAD /products 200 0ms
[Thu Nov 19 18:42:42 2026] 127.0.0.1:47790 Closing
...
