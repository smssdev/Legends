$ node tests.mjs
tests written: 10
on the real code: FAIL
mutants caught: 0 of 5
  survived: >= 10  ->  > 10
  survived: Math.min(  ->  Math.max(
  survived: full / 10  ->  full / 5
  survived: quantity < 1  ->  quantity < 0
  survived: Math.floor(  ->  Math.round(
