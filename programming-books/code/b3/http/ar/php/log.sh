# شغّل الخادم (واتركه يعمل في هذه النافذة)
$ php -S localhost:8000 server.php
[Thu Nov 19 14:47:29 2026] PHP 8.3.6 Development Server (http://localhost:8000) started
[Thu Nov 19 14:47:29 2026] 127.0.0.1:50476 Accepted
[Thu Nov 19 14:47:29 2026] GET /products/1 200 0ms
[Thu Nov 19 14:47:29 2026] 127.0.0.1:50476 Closing
[Thu Nov 19 14:47:29 2026] 127.0.0.1:50490 Accepted
[Thu Nov 19 14:47:29 2026] GET /products/2 200 0ms
[Thu Nov 19 14:47:29 2026] 127.0.0.1:50490 Closing
[Thu Nov 19 14:47:29 2026] 127.0.0.1:50492 Accepted
[Thu Nov 19 14:47:29 2026] GET /products?max_price=15000 200 0ms
[Thu Nov 19 14:47:29 2026] 127.0.0.1:50492 Closing
[Thu Nov 19 14:47:29 2026] 127.0.0.1:50494 Accepted
[Thu Nov 19 14:47:29 2026] HEAD /products 200 0ms
[Thu Nov 19 14:47:29 2026] 127.0.0.1:50494 Closing
...
