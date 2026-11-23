import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {MUTANTS, failures, keepPassing, score, testsOf} from "./lib/mutants.mjs";

const source = fs.readFileSync("price.mjs", "utf8");
let tests = testsOf(await ask(`Write tests for this module, importing test from node:test, assert from node:assert/strict and linePrice from ./price.mjs. Cover normal cases and every boundary. Return only the code, in one code block.\n\n${source}`)) ?? "";
console.log(`tests written: ${tests.match(/\btest\(|\bit\(/g)?.length ?? 0}`);

// First, the tests must pass on the real code: a failure here is a wrong
// test.
const failed = failures(tests, source, "mutants/real");
console.log(`on the real code: ${failed ? `FAIL\n${failed}` : "pass"}`);

// A test that fails on the real code is a wrong test: send the failures
// back once.
if (failed) {
  const request = `Some of these tests fail on the real module, so they are wrong. Fix the expected values (not the module). Return the complete test file, in one code block.\n\n${source}\n\n${tests}\n\n${failed}`;
  tests = testsOf(await ask(request, {maxTokens: 1400})) ?? tests;
  const again = failures(tests, source, "mutants/real");
  console.log(`after one fix: ${again ? `FAIL\n${again}` : "pass"}`);
}

// Then keep only the tests that are right, and measure what they catch.
const kept = keepPassing(tests, source);
console.log(`kept ${kept.kept} of ${kept.total} tests: the ones that pass on the real code`);
tests = kept.tests;
fs.writeFileSync("price.test.mjs", tests);

// Then on each mutant: a good test suite fails on every one of them.
const {killed, survivors} = score(tests, source);
console.log(`mutants caught: ${killed} of ${MUTANTS.length}`);
for (const [from, to] of survivors) {
  console.log(`  survived: ${from}  ->  ${to}`);
}
