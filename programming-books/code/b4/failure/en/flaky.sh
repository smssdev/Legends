# The provider has a bad day
strategy   ok  failed   slowest     total provider saw
$ node caller.ts none
none       30      10   3006 ms   3095 ms           40
$ node caller.ts timeout
timeout    28      12    503 ms    616 ms           40
$ node caller.ts retry
retry      40       0    768 ms   1587 ms           57
