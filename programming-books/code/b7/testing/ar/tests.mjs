import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {MUTANTS, failures, keepPassing, score, testsOf} from "./lib/mutants.mjs";

const source = fs.readFileSync("price.mjs", "utf8");
let tests = testsOf(await ask(`اكتب اختبارات لهذه الوحدة، مستورداً test من node:test وassert من node:assert/strict وlinePrice من ./price.mjs. غطِّ الحالات العادية وكل حد. أعِد الكود فقط، في كتلة كود واحدة.\n\n${source}`)) ?? "";
console.log(`tests written: ${tests.match(/\btest\(|\bit\(/g)?.length ?? 0}`);

// أولاً، يجب أن تنجح الاختبارات على الكود الحقيقي: الفشل هنا اختبار خاطئ.
const failed = failures(tests, source, "mutants/real");
console.log(`on the real code: ${failed ? `FAIL\n${failed}` : "pass"}`);

// الاختبار الذي يفشل على الكود الحقيقي اختبار خاطئ: أرسل الفشل مرة واحدة.
if (failed) {
  const request = `بعض هذه الاختبارات يفشل على الوحدة الحقيقية، فهي خاطئة. أصلح القيم المتوقعة (لا الوحدة). أعِد ملف الاختبارات كاملاً، في كتلة كود واحدة.\n\n${source}\n\n${tests}\n\n${failed}`;
  tests = testsOf(await ask(request, {maxTokens: 1400})) ?? tests;
  const again = failures(tests, source, "mutants/real");
  console.log(`after one fix: ${again ? `FAIL\n${again}` : "pass"}`);
}

// ثم احتفظ بالاختبارات الصحيحة وحدها، وقِس ما تكشفه.
const kept = keepPassing(tests, source);
console.log(`kept ${kept.kept} of ${kept.total} tests: the ones that pass on the real code`);
tests = kept.tests;
fs.writeFileSync("price.test.mjs", tests);

// ثم على كل نسخة متحوّرة: مجموعة الاختبارات الجيدة تفشل على كل واحدة
// منها.
const {killed, survivors} = score(tests, source);
console.log(`mutants caught: ${killed} of ${MUTANTS.length}`);
for (const [from, to] of survivors) {
  console.log(`  survived: ${from}  ->  ${to}`);
}
