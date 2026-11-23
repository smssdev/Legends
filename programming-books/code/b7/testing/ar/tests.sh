$ node tests.mjs
tests written: 0
on the real code: FAIL
no tests in the file
after one fix: FAIL
no tests in the file
kept 0 of 1 tests: the ones that pass on the real code
mutants caught: 0 of 5
  survived: >= 10  ->  > 10
  survived: Math.min(  ->  Math.max(
  survived: full / 10  ->  full / 5
  survived: quantity < 1  ->  quantity < 0
  survived: Math.floor(  ->  Math.round(
