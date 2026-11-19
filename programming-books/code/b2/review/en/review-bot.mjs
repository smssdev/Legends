// code/b2/review/en/review-bot.ts
import { readFileSync } from "node:fs";
var diff = readFileSync(process.argv[2] ?? "pr.diff", "utf8").split("\n");
var findings = [];
var changedFiles = /* @__PURE__ */ new Set();
var file = "";
var line = 0;
var changed = 0;
for (const text of diff) {
  if (text.startsWith("+++ ")) {
    file = text.slice(6);
    changedFiles.add(file);
    continue;
  }
  const hunk = /^@@ -\d+(?:,\d+)? \+(\d+)/.exec(text);
  if (hunk) {
    line = Number(hunk[1]);
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
  const code2 = text.slice(1);
  const say = (message) => findings.push({ file, line, message });
  if (/console\.log\(/.test(code2)) say("console.log left in: remove it, or use the app's logger");
  if (/:\s*any\b/.test(code2)) say("\u201Cany\u201D switches the type checker off here: write the real type");
  if (/[^=!]==[^=]/.test(code2)) say("\u201C==\u201D converts types before comparing: use \u201C===\u201D");
  if (/TODO(?!.*#\d+)/.test(code2)) say("TODO without an issue number: link one (#123), or do it now");
  line++;
}
var isTest = (f) => /\.test\.ts$/.test(f);
var code = [...changedFiles].filter((f) => f.endsWith(".ts") && !isTest(f));
if (code.length > 0 && ![...changedFiles].some(isTest)) findings.push({ file: code[0], line: 1, message: "code changed, but no test changed" });
if (changed > 300) findings.push({ file: "*", line: 0, message: "{n} changed lines: hard to review well; split it (under 300)".replace("{n}", String(changed)) });
for (const f of findings) console.log(`${f.file}:${f.line}  ${f.message}`);
console.log(findings.length ? `${findings.length} findings` : "Nothing for the robot to say. Over to the humans.");
