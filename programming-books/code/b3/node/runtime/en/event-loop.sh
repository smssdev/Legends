# The order things run in
$ node demos/event-loop.ts
script starts
script ends
promise callback
process.nextTick
timer (0 ms)
timer asked for 10 ms, ran after 200 ms
