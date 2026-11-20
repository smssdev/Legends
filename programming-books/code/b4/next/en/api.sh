# The same slots through the API
$ curl -s 'localhost:3000/api/slots?staff_id=1&date=2026-12-01' | jq -c '.data[:2]'
[{"starts_at":"2026-12-01T08:00:00.000Z","ends_at":"2026-12-01T08:30:00.000Z"},{"starts_at":"2026-12-01T08:30:00.000Z","ends_at":"2026-12-01T09:00:00.000Z"}]
# After the bookings in the browser
$ curl -s 'localhost:3000/api/slots?staff_id=1&date=2026-12-01' | jq -c '.data[:2]'
[{"starts_at":"2026-12-01T08:30:00.000Z","ends_at":"2026-12-01T09:00:00.000Z"},{"starts_at":"2026-12-01T09:00:00.000Z","ends_at":"2026-12-01T09:30:00.000Z"}]
# What the database holds
$ psql shop -c 'SELECT id, staff_id, email, lower(during) AS starts_at FROM bookings'
 id | staff_id |      email       |       starts_at        
----+----------+------------------+------------------------
  1 |        1 | sara@example.com | 2026-12-01 08:00:00+00
(1 row)
