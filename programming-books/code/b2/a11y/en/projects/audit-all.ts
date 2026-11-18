import { audit } from "../audit-lib";

// Audit every page, and fail the build if any has a violation
const pages = ["../before.html", "../after.html"];
let total = 0;
for (const page of pages) {
  console.log(`— ${page}`);
  const count = await audit(page);
  if (count === 0) console.log("  No violations found.");
  total += count;
}
console.log(`Total violations: ${total}`);
process.exitCode = total === 0 ? 0 : 1;
