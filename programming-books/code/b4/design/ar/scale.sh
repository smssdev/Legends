# العملاء الستة عشر أنفسهم، عبر موزّع حمل
# نسخة واحدة
$ PORT=3001 node queue.ts &
$ node balancer.ts 3001 &
$ node load.ts http://localhost:3000 16
العملاء         طلب/ث   p50 ms   p99 ms
16                 97      153      703
# نسختان
$ PORT=3001 node queue.ts & PORT=3002 node queue.ts &
$ node balancer.ts 3001 3002 &
$ node load.ts http://localhost:3000 16
العملاء         طلب/ث   p50 ms   p99 ms
16                194       71      147
# ثلاث نسخ
$ PORT=3001 node queue.ts & PORT=3002 node queue.ts & PORT=3003 node queue.ts &
$ node balancer.ts 3001 3002 3003 &
$ node load.ts http://localhost:3000 16
العملاء         طلب/ث   p50 ms   p99 ms
16                289       46      106
