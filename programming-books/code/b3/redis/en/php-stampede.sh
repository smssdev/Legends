# Twenty requests on a cold cache
$ php php/stampede.php naive
naive   20 requests, database queries: 20, 260 ms
$ php php/stampede.php locked
locked  20 requests, database queries: 1, 284 ms
