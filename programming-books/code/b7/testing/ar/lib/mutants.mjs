import fs from "node:fs";
import {execFileSync} from "node:child_process";

// Each mutant is the real module with one small change: a planted bug.
export const MUTANTS = [
  [">= 10", "> 10"],
  ["Math.min(", "Math.max("],
  ["full / 10", "full / 5"],
  ["quantity < 1", "quantity < 0"],
  ["Math.floor(", "Math.round("],
];

// Runs a test file next to a given price.mjs; "" when every test passes,
// otherwise the failing tests with their expected and actual values.
export function failures(tests, source, dir) {
  fs.mkdirSync(dir, {recursive: true});
  fs.writeFileSync(`${dir}/price.mjs`, source);
  fs.writeFileSync(`${dir}/price.test.mjs`, tests);
  try {
    const output = execFileSync("node", ["--test", "--test-reporter=tap", `${dir}/price.test.mjs`], {
      encoding: "utf8",
    });
    // A file with no tests passes too: that is not a passing test suite.
    return /^# tests 0$/m.test(output) ? "no tests ran" : "";
  } catch (error) {
    const lines = `${error.stdout}`.split("\n");
    return lines
      .filter((line) => /^\s*(not ok|expected:|actual:)|^# \w*Error/.test(line))
      .map((line) => line.trim())
      .slice(0, 20)
      .join("\n") || "the test file does not run";
  }
}

// The code block of an answer that contains tests (an answer may also
// quote the module).
export function testsOf(answer) {
  const blocks = [...answer.matchAll(/```(?:\w+)?\n([\s\S]*?)```/g)].map((m) => m[1]);
  return blocks.find((block) => /\btest\(/.test(block)) ?? null;
}

export function passes(tests, source, dir) {
  return failures(tests, source, dir) === "";
}

// How many mutants the tests catch, and which survive. Tests that fail on
// the
// real code would "catch" every mutant, so they score nothing.
export function score(tests, source) {
  if (!passes(tests, source, "mutants/real")) {
    return {killed: 0, survivors: MUTANTS};
  }
  const survivors = MUTANTS.filter(([from, to], i) => {
    return passes(tests, source.replace(from, to), `mutants/m${i + 1}`);
  });
  return {killed: MUTANTS.length - survivors.length, survivors};
}
