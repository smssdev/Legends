# One copy, more and more clients
$ node load.ts http://localhost:3000 1 4 16 64
clients    requests/s   p50 ms   p99 ms
1                  95       10       11
4                  97       30       72
16                 97      153      710
64                 95      223     3733
