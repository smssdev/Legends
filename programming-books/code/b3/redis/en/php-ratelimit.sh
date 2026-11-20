# Five requests per 10 seconds, shared by two servers
$ php php/ratelimit.php
request 1 via server A: allowed (1 of 5)
request 2 via server B: allowed (2 of 5)
request 3 via server A: allowed (3 of 5)
request 4 via server B: allowed (4 of 5)
request 5 via server A: allowed (5 of 5)
request 6 via server B: refused, 429, try again in 10 s
request 7 via server A: refused, 429, try again in 10 s
request 8 via server B: refused, 429, try again in 10 s
