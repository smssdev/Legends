import fs from "node:fs";
import {createRequire} from "node:module";
import {ask} from "./lib/ask.mjs";

const require = createRequire(import.meta.url);
const {calc} = require("./legacy/lib/calc.js");
const code = fs.readFileSync("legacy/lib/calc.js", "utf8");

const calls = [
  [{c: "STD", l: [{p: 4500, q: 2}]}, true],
  [{c: "STD", l: [{p: 2500, q: 10}]}, true],
  [{c: "STD", l: [{p: 2500, q: 10}]}, false],
  [{c: "VIP", l: [{p: 300, q: 1}]}, true],
  [{c: "STD", l: [{p: 10000, q: 2}]}, true],
  [{c: "vip", l: [{p: 4500, q: 2}]}, true],
];

// An explanation is a set of claims. Turn them into predictions, and run
// the real code.
const written = calls.map(([o, d]) => `calc(${JSON.stringify(o)}, ${d})`).join("\n");
const answer = await ask(`${code}\n\nFor each of these calls, what does calc return? Reply with a JSON array of numbers only, in order.\n${written}`);
const predicted = JSON.parse(answer.match(/\[[^\]]*\]/)[0]);
let right = 0;
calls.forEach(([o, d], i) => {
  const actual = calc(o, d);
  right += predicted[i] === actual ? 1 : 0;
  const mark = predicted[i] === actual ? "same " : "WRONG";
  console.log(`${mark} predicted ${String(predicted[i]).padStart(6)}  actual ${String(actual).padStart(6)}`);
});
console.log(`${right} of ${calls.length} predictions right`);
