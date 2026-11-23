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
  minItems: 1,
  maxItems: 8,
});
const diff = fs.readFileSync("changes/save-order.diff", "utf8");
const problems = JSON.parse(await ask(`راجع هذا التغيير. أجب بـ JSON: قائمة مشكلات، لكل منها severity (high أو medium أو low)، والسطر، والمشكلة في جملة واحدة.\n\n${diff}`, {grammar}));

// قيّم المراجعة: المشكلات المزروعة التي وجدتها، وكل ما ذكرته غيرها.
const planted = [
  /password|secret|credential|DB_PASSWORD/i,
  /<=|off-by-one|off by one|out of bounds|undefined/i,
  /insert[^.]*(await|promise)|(await|promise)[^.]*insert|not awaited/i,
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
