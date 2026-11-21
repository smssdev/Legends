# القرارات حتى الآن
$ node adr.ts
0001  Accepted                   قاعدة PostgreSQL واحدة للمنتج كله
0002  Superseded by 0004         المهام الخلفية في طابور Redis
0003  Accepted                   المال قروشاً صحيحة
0004  Accepted                   المهام الخلفية في PostgreSQL
# سجّل قراراً جديداً
$ node adr.ts new Keep job payloads small
docs/adr/0005-keep-job-payloads-small.md
$ node adr.ts
0001  Accepted                   قاعدة PostgreSQL واحدة للمنتج كله
0002  Superseded by 0004         المهام الخلفية في طابور Redis
0003  Accepted                   المال قروشاً صحيحة
0004  Accepted                   المهام الخلفية في PostgreSQL
0005  Proposed                   Keep job payloads small
