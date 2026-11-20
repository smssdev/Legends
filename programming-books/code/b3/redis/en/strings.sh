# Strings, counters and expiry
$ redis-cli SET greeting hello
OK
$ redis-cli GET greeting
"hello"
$ redis-cli GET nothing
(nil)
$ redis-cli INCR visits
(integer) 1
$ redis-cli INCR visits
(integer) 2
$ redis-cli SET session:7f3a 42 EX 1800
OK
$ redis-cli TTL session:7f3a
(integer) 1800
$ redis-cli SET once yes NX
OK
$ redis-cli SET once again NX
(nil)
