# Hashes and sorted sets
$ redis-cli HSET product:2 name 'Spare wheels' price 6000
(integer) 2
$ redis-cli HGET product:2 price
"6000"
$ redis-cli ZADD scores 120 sara 95 omar 140 lina
(integer) 3
$ redis-cli ZINCRBY scores 30 omar
"125"
$ redis-cli ZREVRANGE scores 0 2 WITHSCORES
1) "lina"
2) "140"
3) "omar"
4) "125"
5) "sara"
6) "120"
