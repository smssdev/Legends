import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {
    type: "object",
    properties: {
      severity: {enum: ["high", "medium", "low"]},
      line: {type: "string"},
      problem: {type: "string"},
    },
  },
  maxItems: 8,
});
const diff = fs.readFileSync("changes/save-order.diff", "utf8");
const problems = JSON.parse(await ask(`Review this change. Reply with JSON: a list of problems, each with severity (high, medium or low), the line, and the problem in one sentence.\n\n${diff}`, {grammar}));

// Score the review: planted problems found, and anything else it
// reported.
const planted = [
  /password|secret|credential|DB_PASSWORD/i,
  /<=|off-by-one|off by one|out of bounds|undefined/i,
  /await|promise|async/i,
];
const found = new Set();
for (const {severity, line, problem} of problems) {
  const hit = planted.findIndex((pattern) => pattern.test(`${line} ${problem}`));
  if (hit >= 0) {
    found.add(hit);
  }
  console.log(`${severity.padEnd(6)} ${hit >= 0 ? "planted" : "other  "} ${problem}`);
}
console.log(`--- ${found.size} of 3 planted problems, ${problems.length} reported`);
