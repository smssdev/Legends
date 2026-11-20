# A cache in front of a slow query
$ php php/cache.php
first request    Robot kit, 45000, from PostgreSQL in 204 ms
second request   Robot kit, 45000, from Redis in 0 ms
third request    Robot kit, 45000, from Redis in 0 ms
price changed to 47000, cached copy deleted
after the change Robot kit, 47000, from PostgreSQL in 203 ms
seconds left in Redis: 60
