import { readFileSync } from "node:fs";

// Reads the pull request's diff and comments on the lines a machine can judge
type Finding = { file: string; line: number; message: string };

const diff = readFileSync(process.argv[2] ?? "pr.diff", "utf8").split("\n");
const findings: Finding[] = [];
const changedFiles = new Set<string>();
let file = "";
let line = 0;
let changed = 0;

for (const text of diff) {
  if (text.startsWith("+++ ")) {
    file = text.slice(6); // "+++ b/src/cart/discount.ts"
    changedFiles.add(file);
    continue;
  }
  const hunk = /^@@ -\d+(?:,\d+)? \+(\d+)/.exec(text);
  if (hunk) {
    line = Number(hunk[1]); // Line numbers in the new file start from the @@ header of each part of the diff
    continue;
  }
  if (text.startsWith("-") && !text.startsWith("---")) {
    changed++;
    continue;
  }
  if (!text.startsWith("+") || text.startsWith("+++")) {
    if (text.startsWith(" ")) line++;
    continue;
  }
  changed++;
  const code = text.slice(1);
  const say = (message: string) => findings.push({ file, line, message });
  if (/console\.log\(/.test(code)) say("console.log left in: remove it, or use the app's logger");
  if (/:\s*any\b/.test(code)) say("“any” switches the type checker off here: write the real type");
  if (/[^=!]==[^=]/.test(code)) say("“==” converts types before comparing: use “===”");
  if (/TODO(?!.*#\d+)/.test(code)) say("TODO without an issue number: link one (#123), or do it now");
  line++;
}

const isTest = (f: string) => /\.test\.ts$/.test(f);
const code = [...changedFiles].filter((f) => f.endsWith(".ts") && !isTest(f));
if (code.length > 0 && ![...changedFiles].some(isTest)) findings.push({ file: code[0]!, line: 1, message: "code changed, but no test changed" });
if (changed > 300) findings.push({ file: "*", line: 0, message: "{n} changed lines: hard to review well; split it (under 300)".replace("{n}", String(changed)) });

for (const f of findings) console.log(`${f.file}:${f.line}  ${f.message}`);
console.log(findings.length ? `${findings.length} findings` : "Nothing for the robot to say. Over to the humans.");
