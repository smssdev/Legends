# انشر v2 بإعادة التشغيل في المكان، تحت الحمل
$ node load.ts 8 &   # 8 clients for 8 seconds; at second 2:
$ kill -TERM $V1
$ VERSION=v2 PORT=3001 node server.ts &
$ wait
الثانية    نجح     فشل  النسخ
1          328       0  v1
2          350      90  v1
3          339     208  v2
4          367       0  v2
5          369       0  v2
6          369       0  v2
7          371       0  v2
8          373       0  v2
