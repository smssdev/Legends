# Deploy v2 as a rolling update, under load
$ node load.ts 8 &   # 8 clients for 8 seconds; at second 2:
$ VERSION=v2 PORT=3002 node server.ts &
$ until curl -sf localhost:3002/ready; do sleep 0.1; done
$ curl -s 'localhost:3000/admin/pool?ports=3001,3002'
$ curl -s 'localhost:3000/admin/pool?ports=3002'
$ kill -TERM $V1
$ wait
second      ok  failed  versions
1          323       0  v1
2          361       0  v1
3          359       0  v1
4          370       0  v1 v2
5          365       0  v1 v2
6          366       0  v2
7          368       0  v2
8          371       0  v2
