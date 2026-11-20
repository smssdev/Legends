# The shop queues four confirmations (and one twice)
$ node demos/enqueue.ts
job order-1001 queued in 20.1 ms
job order-1002 queued in 0.8 ms
job order-1003 queued in 0.8 ms
job order-1004 queued in 0.9 ms
job order-1001 queued again; jobs waiting: 4
# Nobody is working yet: the jobs wait in Redis
$ redis-cli LLEN bull:mail:wait
(integer) 4
