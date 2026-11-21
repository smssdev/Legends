# The decisions so far
$ node adr.ts
0001  Accepted                   One PostgreSQL database for the whole product
0002  Superseded by 0004         Background jobs in a Redis queue
0003  Accepted                   Money as whole piastres
0004  Accepted                   Background jobs in PostgreSQL
# Record a new decision
$ node adr.ts new Keep job payloads small
docs/adr/0005-keep-job-payloads-small.md
$ node adr.ts
0001  Accepted                   One PostgreSQL database for the whole product
0002  Superseded by 0004         Background jobs in a Redis queue
0003  Accepted                   Money as whole piastres
0004  Accepted                   Background jobs in PostgreSQL
0005  Proposed                   Keep job payloads small
