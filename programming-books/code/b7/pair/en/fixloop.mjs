import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {failures, runTests} from "./lib/tests.mjs";

// Stop when the tests pass, when the rounds run out, or when the same
// failure comes back.
export async function fixLoop({spec, file, testFile, rounds = 3}) {
  let code = fs.readFileSync(file, "utf8");
  let last = "";
  for (let round = 0; ; round++) {
    const result = runTests(testFile);
    if (result.ok) {
      return `passed after ${round} fixes`;
    }
    const failed = failures(result.output);
    if (round === rounds) {
      return `gave up after ${rounds} fixes: ${result.summary}`;
    }
    if (failed === last) {
      return `stopped: the same failure twice (${result.summary})`;
    }
    last = failed;
    const request = `${spec}\n\n${file}:\n${code}\n\nThe tests failed with this output. Fix bill.mjs (not the tests). Return only the code, in one code block.\n${failed}`;
    code = codeOf(await ask(request)) ?? code;
    fs.writeFileSync(file, code);
  }
}

const broken = `export function splitBill(total, people, tipPercent) {
  const sum = total + (total * tipPercent) / 100;
  return Array(people).fill(sum / people);
}
`;
fs.mkdirSync("loop", {recursive: true});
fs.writeFileSync("loop/bill.mjs", broken);
fs.copyFileSync("bill/bill.test.mjs", "loop/bill.test.mjs");
const spec = "splitBill(total, people, tipPercent) splits a café bill. total is in piastres (an integer), people is a whole number of at least 1, tipPercent is a whole number such as 10. The tip is total * tipPercent / 100, rounded to the nearest piastre. It returns an array with one integer amount per person, adding up exactly to total plus tip; when it does not divide evenly, the first people pay one piastre more. It throws a RangeError if people is less than 1. Examples: splitBill(1000, 3, 10) is [367, 367, 366]; splitBill(995, 2, 15) is [572, 572]; splitBill(1000, 4, 0) is [250, 250, 250, 250].";
const file = "loop/bill.mjs";
console.log(await fixLoop({spec, file, testFile: "loop/bill.test.mjs"}));
