# تغيير لا يستمع إليه أحد، ثم عميل يتصل بعده
$ curl -s -X POST localhost:3000/orders/1001/status -H 'content-type: application/json' -d '{"status":"delivered"}'
$ curl -sN --max-time 1 localhost:3000/orders/1001/events
: متصل بـ server 3000
