# كم تستغرق الأشياء، على هذه الآلة
$ node --env-file=.env latency.ts
العملية                                الوسيط
البحث عن مفتاح في Map                  197 ns
تحليل 1 KB من JSON                     4.4 µs
SHA-256 لـ 1 KB                        2.2 µs
قراءة 4 KB من ملف في الذاكرة المؤقتة   4.8 µs
طلب HTTP إلى localhost                 490.2 µs
SELECT 1 في PostgreSQL (localhost)     87.9 µs
كتابة 4 KB وfsync إلى القرص            266.0 µs
بصمة كلمة مرور بـ scrypt               84.6 ms
