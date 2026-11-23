$ node --test --test-reporter=tap bill/bill.test.mjs | grep -E '^ *(ok|not ok|# (pass|fail))'
    ok 1 - normal case with even division
    ok 2 - uneven division with tip
    ok 3 - tip that needs rounding
    ok 4 - throws RangeError when people is less than 1
    ok 5 - handles tip rounding correctly
    ok 6 - single person pays full amount
ok 1 - splitBill
# pass 6
# fail 0
