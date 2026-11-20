# Ten buyers, one robot kit, four ways to sell it
$ php php/race.php naive
naive        1 in stock, 10 sold, stock now 0
$ php php/race.php atomic
atomic       1 in stock, 1 sold, stock now 0
$ php php/race.php lock
lock         1 in stock, 1 sold, stock now 0
$ php php/race.php serializable
serializable 1 in stock, 1 sold, stock now 0, 9 retries
