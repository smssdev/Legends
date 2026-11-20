# Twenty requests on a cold cache
$ node node/stampede.ts naive
naive   20 requests, database queries: 20, 440 ms
$ node node/stampede.ts locked
locked  20 requests, database queries: 1, 259 ms
