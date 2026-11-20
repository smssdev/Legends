# How long things take, on this machine
$ node --env-file=.env latency.ts
operation                              median
look up a key in a Map                 194 ns
parse 1 KB of JSON                     2.8 µs
SHA-256 of 1 KB                        2.2 µs
read 4 KB from a cached file           4.2 µs
HTTP request to localhost              605.6 µs
PostgreSQL SELECT 1 (localhost)        68.9 µs
write 4 KB and fsync to disk           266.1 µs
hash a password with scrypt            92.4 ms
