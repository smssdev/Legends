# The customer asks to pay a 50 EGP deposit
$ curl -s -X POST localhost:3000/bookings/1/deposit | jq -c
{"checkout_url":"http://localhost:4000/pay/cs_5788321f1466"}
# She pays on the provider's page
$ curl -s -X POST localhost:4000/pay/cs_5788321f1466 | jq -c
{"status":200,"answer":{"result":"applied"}}
# The payment and the booking
$ psql shop -c 'SELECT p.id, p.amount, p.status AS payment, b.status AS booking FROM payments p JOIN bookings b ON b.id = p.booking_id'
 id | amount | payment |  booking  
----+--------+---------+-----------
  1 |   5000 | paid    | confirmed
(1 row)
# The provider delivers the same event again
$ curl -s -X POST localhost:4000/pay/cs_5788321f1466/redeliver | jq -c
{"status":200,"answer":{"result":"duplicate"}}
# Someone forges a webhook
$ curl -s localhost:3000/webhooks/payments -H 'content-type: application/json' -H 'bit-signature: t=1795190000,v1=00ff' -d '{"id":"evt_x","type":"checkout.paid","data":{"checkout_id":"cs_x"}}' | jq -c
{"status":400,"title":"Invalid signature"}
