$ node tests.mjs
tests written: 5
on the real code: FAIL
not ok 1 - linePrice should return correct price for normal cases
not ok 2 - linePrice should throw RangeError when quantity is less than 1
not ok 3 - linePrice should apply 10% off correctly from the 10th cup
not ok 4 - linePrice should not exceed 5000 off even if full price is large
not ok 5 - linePrice should not apply discount for quantity less than 10
after one fix: FAIL
not ok 1 - linePrice should return correct price for normal cases
not ok 2 - linePrice should throw RangeError when quantity is less than 1
not ok 3 - linePrice should apply 10% off correctly from the 10th cup
not ok 4 - linePrice should not exceed 5000 off even if full price is large
not ok 5 - linePrice should not apply discount for quantity less than 10
kept 3 of 5 tests: the ones that pass on the real code
mutants caught: 4 of 5
  survived: Math.floor(  ->  Math.round(
