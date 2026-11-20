// code/b2/review/ar/review-bot.ts
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
  if (/console\.log\(/.test(code2)) say("console.log \u0645\u062A\u0631\u0648\u0643: \u0627\u062D\u0630\u0641\u0647\u060C \u0623\u0648 \u0627\u0633\u062A\u062E\u062F\u0645 \u0623\u062F\u0627\u0629 \u0627\u0644\u0633\u062C\u0644\u0627\u062A \u0641\u064A \u0627\u0644\u062A\u0637\u0628\u064A\u0642");
  if (/:\s*any\b/.test(code2)) say("\u201Cany\u201D \u064A\u0637\u0641\u0626 \u0641\u062D\u0635 \u0627\u0644\u0623\u0646\u0648\u0627\u0639 \u0647\u0646\u0627: \u0627\u0643\u062A\u0628 \u0627\u0644\u0646\u0648\u0639 \u0627\u0644\u062D\u0642\u064A\u0642\u064A");
  if (/[^=!]==[^=]/.test(code2)) say("\u201C==\u201D \u064A\u062D\u0648\u0651\u0644 \u0627\u0644\u0623\u0646\u0648\u0627\u0639 \u0642\u0628\u0644 \u0627\u0644\u0645\u0642\u0627\u0631\u0646\u0629: \u0627\u0633\u062A\u062E\u062F\u0645 \u201C===\u201D");
  if (/TODO(?!.*#\d+)/.test(code2)) say("TODO \u0628\u0644\u0627 \u0631\u0642\u0645 \u0645\u0647\u0645\u0629: \u0627\u0631\u0628\u0637\u0647 \u0628\u0648\u0627\u062D\u062F\u0629 (#123)\u060C \u0623\u0648 \u0623\u0646\u062C\u0632\u0647 \u0627\u0644\u0622\u0646");
  line++;
}
var isTest = (f) => /\.test\.ts$/.test(f);
var code = [...changedFiles].filter((f) => f.endsWith(".ts") && !isTest(f));
if (code.length > 0 && ![...changedFiles].some(isTest)) findings.push({ file: code[0], line: 1, message: "\u062A\u063A\u064A\u0651\u0631 \u0627\u0644\u0643\u0648\u062F\u060C \u0648\u0644\u0645 \u064A\u062A\u063A\u064A\u0631 \u0623\u064A \u0627\u062E\u062A\u0628\u0627\u0631" });
if (changed > 300) findings.push({ file: "*", line: 0, message: "{n} \u0633\u0637\u0631\u0627\u064B \u0645\u062A\u063A\u064A\u0631\u0627\u064B: \u064A\u0635\u0639\u0628 \u0645\u0631\u0627\u062C\u0639\u062A\u0647\u0627 \u062C\u064A\u062F\u0627\u064B\u060C \u0642\u0633\u0651\u0645\u0647 (\u0623\u0642\u0644 \u0645\u0646 300)".replace("{n}", String(changed)) });
for (const f of findings) console.log(`${f.file}:${f.line}  ${f.message}`);
console.log(findings.length ? `${findings.length} \u0645\u0644\u0627\u062D\u0638\u0627\u062A` : "\u0644\u0627 \u0634\u064A\u0621 \u064A\u0642\u0648\u0644\u0647 \u0627\u0644\u0631\u0648\u0628\u0648\u062A. \u0627\u0644\u0643\u0644\u0645\u0629 \u0644\u0644\u0628\u0634\u0631.");
