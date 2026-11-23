import {ask, model} from "./lib/ask.mjs";
import {REVIEWS} from "./data/reviews.mjs";

const TOPICS = {
  price: ["expensive", "price", "cost", "value", "pounds", "cheap"],
  app: ["app", "ordering", "stamps", "crash", "paying"],
  service: ["barista", "wait", "greeted", "kind", "table", "staff"],
  taste: ["latte", "cake", "espresso", "coffee", "bitter", "dry", "tasteless"],
};
const rule = (text) => Object.keys(TOPICS).find((t) => TOPICS[t].some((w) => text.toLowerCase().includes(w)));
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {topic: {enum: ["price", "taste", "service", "app"]}},
});

// Where model and rules disagree, a person decides.
let agreed = 0;
const queue = [];
for (const [text, truth] of REVIEWS) {
  const {topic} = JSON.parse(await ask(`Label this café review with its topic (price, taste, service or app) and its sentiment (pos or neg).\n\n${text}`, {grammar}));
  if (topic === rule(text)) {
    agreed++;
    if (topic !== truth) {
      console.log(`agreed and WRONG: ${text}`);
    }
  } else {
    queue.push(`${text}  (model: ${topic}, rules: ${rule(text) ?? "none"}, truth: ${truth})`);
  }
}
console.log(`${agreed} decided automatically, ${queue.length} for a person:`);
queue.forEach((item) => console.log(`  ${item}`));
