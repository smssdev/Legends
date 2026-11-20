# شاشة تتابع الطلب 1001 بأحداث الخادم المرسلة، بينما يغيّر المتجر حالته
$ curl -s -X POST localhost:3000/orders/1001/status -H 'content-type: application/json' -d '{"status":"paid"}'
$ curl -s -X POST localhost:3000/orders/1001/status -H 'content-type: application/json' -d '{"status":"shipped"}'
