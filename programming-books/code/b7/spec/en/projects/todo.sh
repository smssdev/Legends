$ node todo.mjs && node --test --test-reporter=spec loyalty.test.mjs 2>&1 | grep -E '^ℹ (tests|todo|pass|fail)'
loyalty.test.mjs: 6 pending tests
ℹ tests 6
ℹ pass 0
ℹ fail 0
ℹ todo 6
