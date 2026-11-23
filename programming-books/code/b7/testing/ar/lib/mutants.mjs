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
  // Node counts even an empty file as one passing test: look for tests
  // first.
  if (!/\b(test|it)\(/.test(tests)) {
    return "no tests in the file";
  }
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
  return blocks.find((block) => /\b(test|it)\(/.test(block)) ?? null;
}

export function passes(tests, source, dir) {
  return failures(tests, source, dir) === "";
}

// Keeps the tests that pass on the real code, each run on its own, after
// adding
// any import the file forgot (the two-line fix a developer makes in
// seconds).
export function keepPassing(tests, source) {
  let header = tests.split("\n").filter((line) => /^import /.test(line));
  if (!header.some((line) => line.includes("node:test"))) {
    header = ['import {test} from "node:test";', ...header];
  }
  if (!header.some((line) => line.includes("node:assert"))) {
    header = ['import assert from "node:assert/strict";', ...header];
  }
  let blocks = tests.split(/\n(?=test\()/).filter((block) => block.startsWith("test("));
  if (blocks.length === 0) {
    // Tests inside describe(...): keep or drop the file as one block.
    blocks = [tests.split("\n").filter((line) => !/^import /.test(line)).join("\n")];
  }
  const kept = blocks.filter((block, i) => {
    return passes(`${header.join("\n")}\n\n${block}`, source, `mutants/one${i}`);
  });
  return {tests: `${header.join("\n")}\n\n${kept.join("\n")}\n`, total: blocks.length, kept: kept.length};
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
