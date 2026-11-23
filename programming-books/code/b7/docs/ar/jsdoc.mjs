import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {docExamples} from "./lib/doctest.mjs";
import * as price from "./price.mjs";

const source = fs.readFileSync("price.mjs", "utf8");
const comment = codeOf(await ask(`اكتب تعليق JSDoc لهذه الدالة: جملة واحدة، و@param و@returns لكل قيمة، وثلاثة أسطر @example بالشكل: linePrice(unit, quantity) // => result. أعِد التعليق فقط، في كتلة كود واحدة.\n\n${source}`));
console.log(comment);

// مثال التوثيق ادعاء عن الكود: شغّله.
console.log("--- the examples, run");
for (const {call, claimed, actual, ok} of docExamples(comment, price)) {
  console.log(`${ok ? "true " : "FALSE"} ${call} // => ${claimed}   (real: ${actual})`);
}
