import {localProvider} from "./lib/providers.mjs";

const provider = await localProvider();
const text = {type: "string"};
const grammar = await provider.model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    customer: text,
    items: {
      type: "array",
      items: {
        type: "object",
        properties: {
          drink: {enum: ["latte", "tea", "espresso"]},
          size: {enum: ["small", "large"]},
          count: {type: "integer"},
        },
      },
    },
  },
});
const answer = await provider.complete({system: "Extract the order as JSON: customer, and items with drink, size and count.", prompt: "two large lattes and a small tea for Mona", grammar});
const order = JSON.parse(answer);
console.log(JSON.stringify(order, null, 2));
// The app works with an object, not with text.
const cups = order.items.reduce((sum, item) => sum + item.count, 0);
console.log(`--- ${order.customer}: ${cups} cups`);
