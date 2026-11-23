import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {MUTANTS, passes, score} from "./lib/mutants.mjs";

const source = fs.readFileSync("price.mjs", "utf8");
const tests = codeOf(await ask(`Write tests for this module with node:test, importing assert from node:assert/strict and linePrice from ./price.mjs. Cover normal cases and every boundary. Return only the code, in one code block.\n\n${source}`)) ?? "";
fs.writeFileSync("price.test.mjs", tests);
console.log(`tests written: ${tests.match(/\btest\(|\bit\(/g)?.length ?? 0}`);

// First, the tests must pass on the real code: a failure here is a wrong
// test.
console.log(`on the real code: ${passes(tests, source, "mutants/real") ? "pass" : "FAIL"}`);

// Then on each mutant: a good test suite fails on every one of them.
const {killed, survivors} = score(tests, source);
console.log(`mutants caught: ${killed} of ${MUTANTS.length}`);
for (const [from, to] of survivors) {
  console.log(`  survived: ${from}  ->  ${to}`);
}
