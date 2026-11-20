# The provider is down
strategy   ok  failed   slowest     total provider saw
$ node caller.ts none
none        0      40     99 ms    303 ms           40
$ node caller.ts retry
retry       0      40    646 ms   3968 ms          120
$ node caller.ts breaker
breaker     0      40    633 ms   1027 ms           24
