# The free slots, with a cache in front
$ node --env-file=.env cache-demo.ts
read 5.37 ms  from database  8 free slots
read 0.54 ms  from cache     8 free slots
read 0.31 ms  from cache     8 free slots
booking made, cache cleared
read 1.80 ms  from database  7 free slots
read 0.28 ms  from cache     7 free slots
