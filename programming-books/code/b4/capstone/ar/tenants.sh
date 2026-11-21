# يرى الصالون B حجوزاته وحده، ولا يستطيع فتح حجوزات A
$ curl -s localhost:4000/bookings -H 'x-api-key: key_b'; echo
[{"id":"4","staff":"Sara","email":"nails@example.com"}]
$ curl -s localhost:4000/bookings/1 -H 'x-api-key: key_b'; echo
{"message":"غير موجود"}
$ curl -s localhost:4000/bookings/1 -H 'x-api-key: key_a'; echo
{"id":"1","staff":"Mona","email":"guest@example.com"}
