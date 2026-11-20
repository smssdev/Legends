# Two copies of the server: the client is on 3001, the change is made on 3000
$ redis-cli PUBSUB NUMSUB order:1001
1) "order:1001"
2) (integer) 1
$ curl -s -X POST localhost:3000/orders/1001/status -H 'content-type: application/json' -d '{"status":"paid"}'
$ curl -s -X POST localhost:3000/orders/1001/status -H 'content-type: application/json' -d '{"status":"shipped"}'
