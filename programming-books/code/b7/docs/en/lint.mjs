import {lintCommit} from "./lib/lint.mjs";

// type(scope): subject, at most 72 characters, no full stop, then a blank
// line.
const messages = [
  "fix(price): cap the bulk discount at 3000",
  "Fixed the price thing.",
  "feat: a much longer subject line that keeps going and going past the limit of characters",
  "docs(readme): explain --vip\nthe body comes right after the subject",
];
for (const message of messages) {
  const problems = lintCommit(message);
  console.log(`${problems.length ? "FAIL" : "ok  "} ${message.split("\n")[0]}`);
  for (const problem of problems) {
    console.log(`       ${problem}`);
  }
}
