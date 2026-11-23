import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {failures, runTests} from "./lib/tests.mjs";

// The model writes the tests; a correct implementation checks them.
const correct = `export function splitBill(total, people, tipPercent) {
  if (people < 1) {
    throw new RangeError("people must be at least 1");
  }
  const sum = total + Math.round((total * tipPercent) / 100);
  const base = Math.floor(sum / people);
  const extra = sum - base * people;
  return Array.from({length: people}, (_, i) => base + (i < extra ? 1 : 0));
}
`;
fs.mkdirSync("checked", {recursive: true});
fs.writeFileSync("checked/bill.mjs", correct);
const spec = "splitBill(total, people, tipPercent) splits a café bill. total is in piastres (an integer), people is a whole number of at least 1, tipPercent is a whole number such as 10. The tip is total * tipPercent / 100, rounded to the nearest piastre. It returns an array with one integer amount per person, adding up exactly to total plus tip; when it does not divide evenly, the first people pay one piastre more. It throws a RangeError if people is less than 1. Examples: splitBill(1000, 3, 10) is [367, 367, 366]; splitBill(995, 2, 15) is [572, 572]; splitBill(1000, 4, 0) is [250, 250, 250, 250].";
const tests = codeOf(await ask(`${spec}\n\nWrite tests for this function with node:test and node:assert/strict, importing splitBill from ./bill.mjs. Cover the normal case, uneven division, a tip that needs rounding, and the error. Return only the code, in one code block.`)) ?? "";
fs.writeFileSync("checked/bill.test.mjs", tests);
const result = runTests("checked/bill.test.mjs");
console.log(`tests written by the model, against a correct splitBill: ${result.summary}`);
console.log(failures(result.output) || "(no failures)");
