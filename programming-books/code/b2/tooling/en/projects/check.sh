# Run every check before committing
$ npm run check
~/code/my-shop/src/discount.ts
  2:3  error  Unexpected var, use let or const instead  no-var
✖ 1 problem (1 error, 0 warnings)
  1 error and 0 warnings potentially fixable with the `--fix` option.
# After fixing the problem
$ npm run check
All matched files use Prettier code style!
