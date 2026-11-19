# Node's own test runner finds the *.test.ts files and runs them
$ npm test

> bit-shop@1.0.0 test
> node --env-file=.env.test --test --test-reporter=spec

✔ counts the primes (1.837999ms)
✔ answers /hello (22.565385ms)
✔ refuses a bad limit (6.428715ms)
✔ streams the export as CSV (657.913744ms)
ℹ tests 4
ℹ suites 0
ℹ pass 4
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 890.42946
