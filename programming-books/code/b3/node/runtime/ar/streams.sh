# مليون طلب، نحو 24 MB
$ node demos/make-orders.ts
1000000 طلب في الملف orders.csv
$ ls -lh orders.csv | awk '{print $5, $9}'
24M orders.csv
# اقرأ الملف كله، ثم اجمع
$ node demos/total-read.ts
الإجمالي: 49999500000, أقصى ذاكرة: 202 MB
# اقرأه تدفقاً، سطراً سطراً
$ node demos/total-stream.ts
الإجمالي: 49999500000, أقصى ذاكرة: 84 MB
