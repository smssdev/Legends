# The same 16 clients, through a load balancer
# one copy
$ PORT=3001 node queue.ts &
$ node balancer.ts 3001 &
$ node load.ts http://localhost:3000 16
clients    requests/s   p50 ms   p99 ms
16                 97      153      702
# two copies
$ PORT=3001 node queue.ts & PORT=3002 node queue.ts &
$ node balancer.ts 3001 3002 &
$ node load.ts http://localhost:3000 16
clients    requests/s   p50 ms   p99 ms
16                194       76      164
# three copies
$ PORT=3001 node queue.ts & PORT=3002 node queue.ts & PORT=3003 node queue.ts &
$ node balancer.ts 3001 3002 3003 &
$ node load.ts http://localhost:3000 16
clients    requests/s   p50 ms   p99 ms
16                289       56      157
