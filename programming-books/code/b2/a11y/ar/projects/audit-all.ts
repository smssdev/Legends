import { audit } from "../audit-lib";

// افحص كل صفحة، وأفشل البناء إن كانت في أي منها مخالفة
const pages = ["../before.html", "../after.html"];
let total = 0;
for (const page of pages) {
  console.log(`— ${page}`);
  const count = await audit(page);
  if (count === 0) console.log("  لا مخالفات.");
  total += count;
}
console.log(`مجموع المخالفات: ${total}`);
process.exitCode = total === 0 ? 0 : 1;
