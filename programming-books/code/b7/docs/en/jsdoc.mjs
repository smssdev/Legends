import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {docExamples} from "./lib/doctest.mjs";
import * as price from "./price.mjs";

const source = fs.readFileSync("price.mjs", "utf8");
const comment = codeOf(await ask(`Write a JSDoc comment for this function: one sentence, @param and @returns for each value, and three @example lines in the form: linePrice(unit, quantity) // => result. Return only the comment, in one code block.\n\n${source}`));
console.log(comment);

// A documentation example is a claim about the code: run it.
console.log("--- the examples, run");
for (const {call, claimed, actual, ok} of docExamples(comment, price)) {
  console.log(`${ok ? "true " : "FALSE"} ${call} // => ${claimed}   (real: ${actual})`);
}
