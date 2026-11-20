# لا أحد سجّل الدخول
$ curl -s -o /dev/null -w '%{http_code} → %{redirect_url}\n' localhost:3000/owner
307 → http://localhost:3000/login
$ curl -s localhost:3000/api/owner/bookings | jq -c
{"title":"لم تسجّل الدخول","status":401}
# صاحبة صالون بِت تسجّل الدخول عبر الواجهة البرمجية
$ TOKEN=$(curl -s localhost:3000/api/login -H 'content-type: application/json' -d '{"email":"owner@bithair.example","password":"a long password"}' | jq -r .token)
$ OMAR=$(curl -s localhost:3000/api/login -H 'content-type: application/json' -d '{"email":"omar@bithair.example","password":"a long password"}' | jq -r .token)
# حجوزات عملها هي فقط
$ curl -s localhost:3000/api/owner/bookings -H "authorization: Bearer $TOKEN" | jq -c '.data[] | [.id, .staff, .email, .status]'
[1,"منى","sara@example.com","confirmed"]
[3,"عمر","nour@example.com","confirmed"]
# حجز في عيادة نور: غير موجود
$ curl -s -X POST localhost:3000/api/owner/bookings/2/cancel -H "authorization: Bearer $TOKEN" | jq -c
{"title":"غير موجود","status":404}
# عمر موظف: يرى ولا يلغي
$ curl -s -X POST localhost:3000/api/owner/bookings/1/cancel -H "authorization: Bearer $OMAR" | jq -c
{"title":"غير مسموح","status":403}
# صاحبة العمل تلغي حجزاً لها
$ curl -s -X POST localhost:3000/api/owner/bookings/1/cancel -H "authorization: Bearer $TOKEN" | jq -c
{"cancelled":true}
# ما تحفظه قاعدة البيانات
$ psql shop -c 'SELECT id, staff_id, email, status FROM bookings ORDER BY id'
 id | staff_id |      email       |  status   
----+----------+------------------+-----------
  1 |        1 | sara@example.com | cancelled
  2 |        3 | ali@example.com  | confirmed
  3 |        2 | nour@example.com | confirmed
(3 rows)
$ psql shop -c "SELECT left(token_hash, 12) || '…' AS token_hash, user_id, expires_at > now() AS valid FROM sessions"
  token_hash   | user_id | valid 
---------------+---------+-------
 84b716423e7f… |       1 | t
 78cdd0c7364f… |       2 | t
(2 rows)
