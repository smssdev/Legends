# Ten buyers, one robot kit, four ways to sell it
$ node node/race.ts naive
naive        1 in stock, 10 sold, stock now 0
$ node node/race.ts atomic
atomic       1 in stock, 1 sold, stock now 0
$ node node/race.ts lock
lock         1 in stock, 1 sold, stock now 0
$ node node/race.ts serializable
serializable 1 in stock, 1 sold, stock now 0, 9 retries
