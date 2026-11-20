# Start the server (and leave it running in this terminal)
$ php -S localhost:8000 server.php
[Thu Nov 19 18:42:39 2026] PHP 8.5.13 Development Server (http://localhost:8000) started
[Thu Nov 19 18:42:39 2026] 127.0.0.1:51706 Accepted
[Thu Nov 19 18:42:39 2026] GET /products/1 200 0ms
[Thu Nov 19 18:42:39 2026] 127.0.0.1:51706 Closing
[Thu Nov 19 18:42:39 2026] 127.0.0.1:51710 Accepted
[Thu Nov 19 18:42:39 2026] GET /products/2 200 0ms
[Thu Nov 19 18:42:39 2026] 127.0.0.1:51710 Closing
[Thu Nov 19 18:42:39 2026] 127.0.0.1:51722 Accepted
[Thu Nov 19 18:42:39 2026] GET /products?max_price=15000 200 0ms
[Thu Nov 19 18:42:39 2026] 127.0.0.1:51722 Closing
[Thu Nov 19 18:42:39 2026] 127.0.0.1:51738 Accepted
[Thu Nov 19 18:42:39 2026] HEAD /products 200 0ms
[Thu Nov 19 18:42:39 2026] 127.0.0.1:51738 Closing
...
