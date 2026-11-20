# Nobody signed in
$ curl -s -o /dev/null -w '%{http_code} → %{redirect_url}\n' localhost:3000/owner
307 → http://localhost:3000/login
$ curl -s localhost:3000/api/owner/bookings | jq -c
{"title":"Not signed in","status":401}
# The owner of Bit Hair Studio signs in through the API
$ TOKEN=$(curl -s localhost:3000/api/login -H 'content-type: application/json' -d '{"email":"owner@bithair.example","password":"a long password"}' | jq -r .token)
$ OMAR=$(curl -s localhost:3000/api/login -H 'content-type: application/json' -d '{"email":"omar@bithair.example","password":"a long password"}' | jq -r .token)
# Only her own business's bookings
$ curl -s localhost:3000/api/owner/bookings -H "authorization: Bearer $TOKEN" | jq -c '.data[] | [.id, .staff, .email, .status]'
[1,"Mona","sara@example.com","confirmed"]
[3,"Omar","nour@example.com","confirmed"]
# A booking of Nour Clinic: not found
$ curl -s -X POST localhost:3000/api/owner/bookings/2/cancel -H "authorization: Bearer $TOKEN" | jq -c
{"title":"Not found","status":404}
# Omar is staff: he may see, not cancel
$ curl -s -X POST localhost:3000/api/owner/bookings/1/cancel -H "authorization: Bearer $OMAR" | jq -c
{"title":"Not allowed","status":403}
# The owner cancels her own booking
$ curl -s -X POST localhost:3000/api/owner/bookings/1/cancel -H "authorization: Bearer $TOKEN" | jq -c
{"cancelled":true}
# What the database holds
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
 8fee3dbe94bb… |       1 | t
 4bd6c10c5678… |       2 | t
(2 rows)
