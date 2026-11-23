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

// Runs a test file next to a given price.mjs; true when every test
// passes.
export function passes(tests, source, dir) {
  fs.mkdirSync(dir, {recursive: true});
  fs.writeFileSync(`${dir}/price.mjs`, source);
  fs.writeFileSync(`${dir}/price.test.mjs`, tests);
  try {
    execFileSync("node", ["--test", `${dir}/price.test.mjs`], {stdio: "pipe"});
    return true;
  } catch {
    return false;
  }
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
