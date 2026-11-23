import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {docExamples} from "./lib/doctest.mjs";

// The code changed after the comment was written; the examples know
// before the model does.
const source = fs.readFileSync("changed/price.mjs", "utf8");
const answer = await ask(`Here is a function and its documentation. Is every statement in the documentation still true of the code? Answer yes or no on the first line, then list what is wrong.\n\n${source}`, {maxTokens: 300});
console.log(answer);
const exports = await import("./changed/price.mjs");
const failing = docExamples(source, exports).filter((r) => !r.ok);
console.log(`--- examples run: ${failing.length} no longer true`);
for (const {call, claimed, actual} of failing) {
  console.log(`   ${call} // => ${claimed}   (real: ${actual})`);
}
