# The same report two ways: count the queries
$ node --env-file=.env demos/n-plus-one.ts
one by one  200 orders, 201 queries, 74 ms
at once     200 orders, 1 queries, 3 ms
