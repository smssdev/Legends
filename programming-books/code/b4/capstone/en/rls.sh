# What the database itself enforces
$ APP=postgres://app_user:app@localhost/shop
$ psql $APP -c 'SELECT count(*) FROM bookings'
 count 
-------
     0
(1 row)
$ psql $APP -q -c 'SET app.salon_id = 2' \
    -c 'SELECT id, staff, email FROM bookings'
 id | staff |       email       
----+-------+-------------------
  4 | Sara  | nails@example.com
(1 row)
