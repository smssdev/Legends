import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";
import {linePrice} from "./price.mjs";

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {
    type: "object",
    properties: {unit: {type: "integer"}, quantity: {type: "integer"}, why: {type: "string"}},
  },
  maxItems: 8,
});
const source = fs.readFileSync("price.mjs", "utf8");
const edges = JSON.parse(await ask(`List the inputs that best test the boundaries of linePrice, as JSON: unit, quantity, and why.\n\n${source}`, {grammar}));

// Run each edge case on the real function and show the result.
for (const {unit, quantity, why} of edges) {
  let result;
  try {
    result = linePrice(unit, quantity);
  } catch (error) {
    result = error.name;
  }
  console.log(`${String(unit).padStart(6)} x ${String(quantity).padEnd(4)} = ${String(result).padEnd(10)} ${why}`);
}
