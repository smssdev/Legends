# شهر واحد، من 24 قسماً
$ psql shop -At -c "EXPLAIN (COSTS OFF) SELECT count(*) FROM bookings WHERE starts_at >= '2026-03-01' AND starts_at < '2026-04-01'" | grep -v Filter
Aggregate
  ->  Seq Scan on bookings_2026_03 bookings
# حذف ستة أشهر: DELETE
$ psql shop -f delete.sql
DELETE 521279
Time: 217.542 ms
# حذف ستة أشهر: إسقاط الأقسام
$ psql shop -f drop.sql
DROP TABLE
Time: 7.506 ms
$ psql shop -c 'SELECT count(*) FROM bookings'
 count  
--------
 948801
(1 row)
