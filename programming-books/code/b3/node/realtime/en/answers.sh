# A change while nobody is listening, then a client that connects afterwards
$ curl -s -X POST localhost:3000/orders/1001/status -H 'content-type: application/json' -d '{"status":"delivered"}'
$ curl -sN --max-time 1 localhost:3000/orders/1001/events
: connected to server 3000
