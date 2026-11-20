# A screen follows order 1001 with server-sent events, while the shop changes its status
$ curl -s -X POST localhost:3000/orders/1001/status -H 'content-type: application/json' -d '{"status":"paid"}'
$ curl -s -X POST localhost:3000/orders/1001/status -H 'content-type: application/json' -d '{"status":"shipped"}'
