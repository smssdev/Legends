$ cd cafe && node --test --test-reporter=tap | grep -E '^(not ok|ok|# (pass|fail))'
ok 1 - no discount below 10 cups
not ok 2 - 10% off from the 10th cup
not ok 3 - at most 5000 off
# pass 1
# fail 2
