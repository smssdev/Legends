import fs from "node:fs";
import {createRequire} from "node:module";
import {ask, codeOf} from "./lib/ask.mjs";

const require = createRequire(import.meta.url);
const original = fs.readFileSync("legacy/calc.js", "utf8");
const code = codeOf(await ask(`Refactor this file for readability: modern JavaScript, clear names, no var. It must behave exactly the same for every input, and keep module.exports = {calc}. Return only the code, in one code block.\n\n${original}`)) ?? "";
fs.writeFileSync("legacy/calc2.js", code);
console.log(code);

// 500 random orders, including the edges: the refactor must give the same
// total for every one.
const before = require("./legacy/calc.js").calc;
let after;
try {
  after = require("./legacy/calc2.js").calc;
} catch (error) {
  console.log(`--- the refactor does not load: ${error.message.split("\n")[0]}`);
  process.exit(0);
}
let seed = 7;
const random = (n) => ((seed = (seed * 1103515245 + 12345) % 2147483648) % n);
const types = ["VIP", "vip", "STD"];
let differ = 0;
let example = "";
for (let i = 0; i < 500; i++) {
  const lines = Array.from({length: 1 + random(3)}, () => ({p: 100 * random(80), q: 1 + random(9)}));
  const order = {c: types[random(3)], l: i < 3 ? [{p: 10000, q: 2}] : lines};
  const d = random(2) === 1;
  const [x, y] = [before(order, d), after(order, d)];
  if (x !== y) {
    differ++;
    example ||= `${JSON.stringify(order)}, ${d}: before ${x}, after ${y}`;
  }
}
console.log(`--- 500 random orders: ${differ} differ`);
console.log(example || "(none)");
