# One month, out of 24 partitions
$ psql shop -At -c "EXPLAIN (COSTS OFF) SELECT count(*) FROM bookings WHERE starts_at >= '2026-03-01' AND starts_at < '2026-04-01'" | grep -v Filter
Aggregate
  ->  Seq Scan on bookings_2026_03 bookings
# Removing six months: DELETE
$ psql shop -f delete.sql
DELETE 521279
Time: 230.292 ms
# Removing six months: dropping partitions
$ psql shop -f drop.sql
DROP TABLE
Time: 5.334 ms
$ psql shop -c 'SELECT count(*) FROM bookings'
 count  
--------
 948801
(1 row)
