$ node tests.mjs
tests written: 6
on the real code: FAIL
not ok 1 - linePrice should return correct price for normal cases
not ok 2 - linePrice should apply 10% off from the 10th cup
not ok 3 - linePrice should not exceed 5000 off discount
not ok 4 - linePrice should throw RangeError for invalid quantity
not ok 5 - linePrice should handle edge cases with zero unit price
not ok 6 - linePrice should handle large quantities with capped discount
after one fix: FAIL
# ReferenceError: test is not defined
not ok 1 - mutants/real/price.test.mjs
mutants caught: 0 of 5
  survived: >= 10  ->  > 10
  survived: Math.min(  ->  Math.max(
  survived: full / 10  ->  full / 5
  survived: quantity < 1  ->  quantity < 0
  survived: Math.floor(  ->  Math.round(
