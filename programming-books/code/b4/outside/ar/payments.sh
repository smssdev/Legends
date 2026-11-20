# الزبونة تطلب دفع عربون 50 جنيهاً
$ curl -s -X POST localhost:3000/bookings/1/deposit | jq -c
{"checkout_url":"http://localhost:4000/pay/cs_0a2c70b02406"}
# تدفع في صفحة المزوّد
$ curl -s -X POST localhost:4000/pay/cs_0a2c70b02406 | jq -c
{"status":200,"answer":{"result":"applied"}}
# الدفعة والحجز
$ psql shop -c 'SELECT p.id, p.amount, p.status AS payment, b.status AS booking FROM payments p JOIN bookings b ON b.id = p.booking_id'
 id | amount | payment |  booking  
----+--------+---------+-----------
  1 |   5000 | paid    | confirmed
(1 row)
# المزوّد يسلّم الحدث نفسه ثانية
$ curl -s -X POST localhost:4000/pay/cs_0a2c70b02406/redeliver | jq -c
{"status":200,"answer":{"result":"duplicate"}}
# أحدهم يزوّر webhook
$ curl -s localhost:3000/webhooks/payments -H 'content-type: application/json' -H 'bit-signature: t=1795190000,v1=00ff' -d '{"id":"evt_x","type":"checkout.paid","data":{"checkout_id":"cs_x"}}' | jq -c
{"status":400,"title":"توقيع غير صالح"}
