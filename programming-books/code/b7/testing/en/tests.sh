$ node tests.mjs
tests written: 6
on the real code: FAIL
not ok 3 - linePrice caps discount at 5000
expected: 900000
actual: 995000
not ok 6 - linePrice handles large quantities with high unit price
expected: 90000
actual: 95000
after one fix: FAIL
not ok 3 - linePrice caps discount at 5000
expected: 900000
actual: 995000
not ok 6 - linePrice handles large quantities with high unit price
expected: 90000
actual: 95000
mutants caught: 0 of 5
  survived: >= 10  ->  > 10
  survived: Math.min(  ->  Math.max(
  survived: full / 10  ->  full / 5
  survived: quantity < 1  ->  quantity < 0
  survived: Math.floor(  ->  Math.round(
