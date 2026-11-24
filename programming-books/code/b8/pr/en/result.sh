$ git log --oneline main..HEAD && git diff --stat main && cat PR.md
e043548 fix(price): keep piastres when totalling a bill (#42)
 src/price.mjs       | 2 +-
 test/price.test.mjs | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
## What and why

Bills with piastres were totalled as if they had none: `parseInt("85.50")` is 85. `total` now reads the bill with `Number`.

## How it was tested

New test: a bill of 85.50 at 10% gives 94.05, the example from the issue. All tests pass with `node --test`.

## Closes

#42
