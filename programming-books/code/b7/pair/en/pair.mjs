import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {broken, failures, runTests} from "./lib/tests.mjs";

// The specification, written once and used for every step.
const spec = "splitBill(total, people, tipPercent) splits a café bill. total is in piastres (an integer), people is a whole number of at least 1, tipPercent is a whole number such as 10. The tip is total * tipPercent / 100, rounded to the nearest piastre. It returns an array with one integer amount per person, adding up exactly to total plus tip; when it does not divide evenly, the first people pay one piastre more. It throws a RangeError if people is less than 1. Examples: splitBill(1000, 3, 10) is [367, 367, 366]; splitBill(995, 2, 15) is [572, 572]; splitBill(1000, 4, 0) is [250, 250, 250, 250].";

// Small steps: a plan, then tests, then code. Each step is a fresh
// request with what it needs.
console.log("== plan\n" + (await ask(`Before writing any code, list in at most five short lines the steps you would take to implement this:\n\n${spec}`)));

let tests = codeOf(await ask(`${spec}\n\nWrite tests for this function with node:test and node:assert/strict, importing splitBill from ./bill.mjs. Cover the normal case, uneven division, a tip that needs rounding, and the error. Return only the code, in one code block.`)) ?? "";
const count = tests.match(/\btest\(|\bit\(/g)?.length ?? 0;
console.log(`== tests: bill/bill.test.mjs, ${count} tests`);

// Before any code: run the tests against an empty splitBill. They must
// fail on their assertions, not because the test file itself is broken.
const empty = "export function splitBill() {\n  return [];\n}\n";
for (let round = 1; ; round++) {
  fs.writeFileSync("bill/bill.mjs", empty);
  fs.writeFileSync("bill/bill.test.mjs", tests);
  const result = runTests("bill/bill.test.mjs");
  const fine = !broken(result.output);
  console.log(`== tests against an empty splitBill: ${result.summary}`);
  console.log(fine ? "   they fail on their assertions: good" : failures(result.output));
  if (fine || round === 3) {
    break;
  }
  // If the model cannot fix its own tests, the developer adds what they
  // know, as a pair would.
  const hint = round > 1 ? "\nA hint from the developer: assert is the default export of node:assert/strict; node:test does not provide it." : "";
  const request = `${spec}\n\nbill.test.mjs:\n${tests}\n\nThese tests do not run: they fail before testing anything, with this output. Fix the test file. Return only the code, in one code block.${hint}\n${failures(result.output)}`;
  if (hint) {
    console.log(`   (the developer adds: A hint from the developer: assert is the default export of node:assert/strict; node:test does not provide it.)`);
  }
  tests = codeOf(await ask(request)) ?? tests;
}

let code = codeOf(await ask(`${spec}\n\nWrite bill.mjs, exporting splitBill. Return only the code, in one code block.`));

// Run the real tests; if they fail, send the output back, at most three
// times.
for (let round = 1; ; round++) {
  fs.writeFileSync("bill/bill.mjs", code);
  const result = runTests("bill/bill.test.mjs");
  console.log(`== round ${round}: ${result.summary}`);
  if (result.ok || round === 4) {
    break;
  }
  console.log(failures(result.output));
  const request = `${spec}\n\nbill.mjs:\n${code}\n\nThe tests failed with this output. Fix bill.mjs (not the tests). Return only the code, in one code block.\n${failures(result.output)}`;
  // An answer without code is not written over the file.
  code = codeOf(await ask(request)) ?? code;
}
