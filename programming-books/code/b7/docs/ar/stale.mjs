import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {docExamples} from "./lib/doctest.mjs";

// تغيّر الكود بعد كتابة التعليق؛ والأمثلة تعرف قبل النموذج.
const source = fs.readFileSync("changed/price.mjs", "utf8");
const answer = await ask(`هذه دالة وتوثيقها. هل كل عبارة في التوثيق ما زالت صحيحة عن الكود؟ أجب بنعم أو لا في السطر الأول، ثم اسرد ما هو خاطئ.\n\n${source}`, {maxTokens: 300});
console.log(answer);
const exports = await import("./changed/price.mjs");
const failing = docExamples(source, exports).filter((r) => !r.ok);
console.log(`--- examples run: ${failing.length} no longer true`);
for (const {call, claimed, actual} of failing) {
  console.log(`   ${call} // => ${claimed}   (real: ${actual})`);
}
