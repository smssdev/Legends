# هل الكود منسّق؟
$ npx prettier --check src
Checking formatting...
[warn] src/format.ts
[warn] src/style.css
[warn] Code style issues found in 2 files. Run Prettier with --write to fix.
# نسّق كل الملفات
$ npx prettier --write src
src/format.ts 54ms
src/main.ts 15ms (unchanged)
src/products.ts 7ms (unchanged)
src/style.css 18ms
$ cat src/format.ts
export function formatPrice(value: number): string {
  return `${value.toFixed(2)} جنيهاً`;
}
