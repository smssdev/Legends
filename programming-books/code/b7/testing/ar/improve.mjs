import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {MUTANTS, passes, score, testsOf} from "./lib/mutants.mjs";

// أرِ النموذج النسخ المتحوّرة التي فاتت اختباراته، وقيّم الاختبارات
// الجديدة.
const source = fs.readFileSync("price.mjs", "utf8");
const tests = fs.readFileSync("price.test.mjs", "utf8");
const first = score(tests, source);
console.log(`before: ${first.killed} of ${MUTANTS.length} caught`);
if (first.survivors.length === 0) {
  process.exit(0);
}
const broken = first.survivors
  .map(([from, to]) => `--- ${from} changed to ${to}:\n${source.replace(from, to)}`)
  .join("\n");
const request = `هذه الاختبارات تنجح، لكنها تنجح أيضاً على كل نسخة معطوبة من هذه النسخ من الوحدة، فهي تفوّت أخطاء حقيقية. أضف اختبارات تفشل على النسخ المعطوبة وتنجح على الحقيقية. أعِد ملف الاختبارات كاملاً، في كتلة كود واحدة.\n\n--- price.mjs:\n${source}\n\n${broken}\n\n--- price.test.mjs:\n${tests}`;
const better = testsOf(await ask(request, {maxTokens: 1400})) ?? tests;
const real = passes(better, source, "mutants/real2");
const second = score(better, source);
console.log(`after:  ${second.killed} of ${MUTANTS.length} caught; on the real code: ${real ? "pass" : "FAIL"}`);
