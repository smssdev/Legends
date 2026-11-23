$ node --test --test-reporter=tap bill/bill.test.mjs | grep -E '^ *(ok|not ok|# (pass|fail))'
not ok 1 - bill/bill.test.mjs
# pass 0
# fail 1
