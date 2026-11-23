import {createRequire} from "node:module";
import {ask, model} from "./lib/ask.mjs";

const require = createRequire(import.meta.url);
const {calc} = require("./legacy/lib/calc.js");
const numbers = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "number"},
});

// Check an explanation by asking it, not the code, for the results.
export async function checkExplanation(explanation, calls) {
  const written = calls.map(([o, d]) => `calc(${JSON.stringify(o)}, ${d})`);
  const prompt =
    `Here are the rules of a function calc:\n${explanation}\n\n` +
    `Using only these rules, what does each call return? Reply with a JSON array of numbers only.\n${written.join("\n")}`;
  const predicted = JSON.parse(await ask(prompt, {grammar: numbers}));
  return calls.map(([o, d], i) => [predicted[i], calc(o, d)]);
}

const calls = [
  [{c: "STD", l: [{p: 4500, q: 2}]}, true],
  [{c: "STD", l: [{p: 2500, q: 10}]}, true],
  [{c: "STD", l: [{p: 2500, q: 10}]}, false],
  [{c: "VIP", l: [{p: 300, q: 1}]}, true],
  [{c: "STD", l: [{p: 10000, q: 2}]}, true],
  [{c: "vip", l: [{p: 4500, q: 2}]}, true],
];

const explanations = {
  vague: "It adds up the order and gives discounts to big orders and VIP customers.",
  exact: "Sum price times quantity over the lines. If d is true and the sum is above 20000, " + "subtract 10% rounded down. Then if c is exactly VIP, subtract 500. Never below 0.",
};
for (const [name, text] of Object.entries(explanations)) {
  const pairs = await checkExplanation(text, calls);
  const right = pairs.filter(([p, a]) => p === a).length;
  console.log(`${name}: ${right} of ${calls.length}  ${JSON.stringify(pairs.map(([p]) => p))}`);
}
console.log(`actual: ${JSON.stringify(calls.map(([o, d]) => calc(o, d)))}`);
