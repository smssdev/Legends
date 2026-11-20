# 5 requests a second for one client, 8 tries
$ node --env-file=.env ratelimit.ts
request   ms   
      1     0 allowed
      2     0 allowed
      3     0 allowed
      4     0 allowed
      5     0 allowed
      6     0 refused
      7  1000 allowed
      8  1000 allowed
