import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {MUTANTS, passes, score} from "./lib/mutants.mjs";

// Show the model the mutants its tests missed, and score the new tests.
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
const request = `These tests pass, but they also pass on each of these broken versions of the module, so they miss real bugs. Add tests that fail on the broken versions and pass on the real one. Return the complete test file, in one code block.\n\n--- price.mjs:\n${source}\n\n${broken}\n\n--- price.test.mjs:\n${tests}`;
const better = codeOf(await ask(request, {maxTokens: 1400})) ?? tests;
const real = passes(better, source, "mutants/real2");
const second = score(better, source);
console.log(`after:  ${second.killed} of ${MUTANTS.length} caught; on the real code: ${real ? "pass" : "FAIL"}`);
