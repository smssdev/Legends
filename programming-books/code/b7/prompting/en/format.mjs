import {ask, model} from "./lib/ask.mjs";

const orders = ["Two large lattes for Omar", "Sara wants one small tea", "an espresso for Ali, small please", "Mona: 3 large teas", "a latte for Hassan"];

// Without a grammar, the model is asked for JSON and may or may not give
// it.
// With a grammar built from a JSON schema, it cannot produce anything
// else.
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    name: {type: "string"},
    drink: {enum: ["latte", "tea", "espresso"]},
    size: {enum: ["small", "large", "unknown"]},
    count: {type: "integer"},
  },
});

for (const [label, options] of [["no grammar", {}], ["schema", {grammar}]]) {
  console.log(`--- ${label}`);
  for (const order of orders) {
    const answer = await ask("Read this coffee order and reply with JSON only, with the fields name, drink, size and count. Order: " + order, options);
    try {
      console.log(JSON.stringify(JSON.parse(answer)));
    } catch {
      console.log(`not JSON: ${JSON.stringify(answer.slice(0, 60))}...`);
    }
  }
}
