# Deploy v2 by restarting in place, under load
$ node load.ts 8 &   # 8 clients for 8 seconds; at second 2:
$ kill -TERM $V1
$ VERSION=v2 PORT=3001 node server.ts &
$ wait
second      ok  failed  versions
1          328       0  v1
2          339      91  v1
3          348      83  v2
4          364       0  v2
5          370       0  v2
6          370       0  v2
7          371       0  v2
8          362       0  v2
