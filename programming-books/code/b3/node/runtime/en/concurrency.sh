# Waiting for three services
$ node demos/concurrency.ts
one after another: 903 ms [ 7, 45000, 4.5 ]
all at once: 401 ms [ 7, 45000, 4.5 ]
one fails, the others still count: 301 ms [ 7, 45000, 'failed' ]
with a time limit of 250 ms: 301 ms [ 7, 45000, 'skipped (too slow)' ]
