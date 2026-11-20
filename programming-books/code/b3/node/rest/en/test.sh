# The tests talk to the app without a network, with inject
$ npm test

> bit-shop-api@1.0.0 test
> node --test --test-reporter=spec

✔ walks every page without repeats or gaps (130.892001ms)
✔ sorts by price, highest first (10.661887ms)
✔ replays an order instead of creating it twice (17.569112ms)
✔ refuses a stale update with 412 (10.551944ms)
✔ answers 422 with every invalid field (12.697298ms)
ℹ tests 5
ℹ suites 0
ℹ pass 5
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 464.396611
