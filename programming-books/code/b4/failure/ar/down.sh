# المزوّد معطل
الإستراتيجية نجح     فشل    الأبطأ   المجموع  رأى المزوّد
$ node caller.ts none
none        0      40     88 ms    305 ms           40
$ node caller.ts retry
retry       0      40    622 ms   3878 ms          120
$ node caller.ts breaker
breaker     0      40    484 ms    807 ms           24
