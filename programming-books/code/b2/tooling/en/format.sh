# Is the code formatted?
$ npx prettier --check src
Checking formatting...
[warn] src/format.ts
[warn] src/style.css
[warn] Code style issues found in 2 files. Run Prettier with --write to fix.
# Format every file
$ npx prettier --write src
src/format.ts 67ms
src/main.ts 22ms (unchanged)
src/products.ts 8ms (unchanged)
src/style.css 19ms
$ cat src/format.ts
export function formatPrice(value: number): string {
  return `${value.toFixed(2)} EGP`;
}
