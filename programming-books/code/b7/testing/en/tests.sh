$ node tests.mjs
tests written: 8
on the real code: FAIL
not ok 3 - linePrice caps the discount at 5000
expected: 180000
actual: 195000
not ok 6 - linePrice handles large quantities with discount cap
expected: 95000
actual: 995000
not ok 8 - linePrice with very large unit price and quantity
expected: 9000000
actual: 9995000
after one fix: FAIL
# SyntaxError: missing ) after argument list
not ok 1 - mutants/real/price.test.mjs
kept 6 of 8 tests: the ones that pass on the real code
mutants caught: 4 of 5
  survived: Math.floor(  ->  Math.round(
