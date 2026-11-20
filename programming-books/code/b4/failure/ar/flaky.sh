# المزوّد في يوم سيئ
الإستراتيجية نجح     فشل    الأبطأ   المجموع  رأى المزوّد
$ node caller.ts none
none       30      10   3005 ms   3106 ms           40
$ node caller.ts timeout
timeout    28      12    503 ms    618 ms           40
$ node caller.ts retry
retry      40       0    937 ms   1838 ms           57
