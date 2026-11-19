# مشغّل الاختبارات في Node يجد ملفات ‎*.test.ts ويشغّلها
$ npm test

> bit-shop@1.0.0 test
> node --env-file=.env.test --test --test-reporter=spec

✔ يعدّ الأعداد الأولية (1.510008ms)
✔ يرد على /hello (21.072719ms)
✔ يرفض limit غير الصالح (7.515115ms)
✔ يبث التصدير بصيغة CSV (580.30739ms)
ℹ tests 4
ℹ suites 0
ℹ pass 4
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 807.74761
