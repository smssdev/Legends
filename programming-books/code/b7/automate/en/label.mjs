import {ask, model} from "./lib/ask.mjs";
import {REVIEWS} from "./data/reviews.mjs";

// The plain way: keyword rules, written in five minutes.
const TOPICS = {
  price: ["expensive", "price", "cost", "value", "pounds", "cheap"],
  app: ["app", "ordering", "stamps", "crash", "paying"],
  service: ["barista", "wait", "greeted", "kind", "table", "staff"],
  taste: ["latte", "cake", "espresso", "coffee", "bitter", "dry", "tasteless"],
};
const NEGATIVE = ["too", "crashed", "cold", "long", "dry", "tasteless", "nobody", "dirty", "not", "bitter", "can't"];
function rules(text) {
  const lower = text.toLowerCase();
  const topic = Object.keys(TOPICS).find((t) => TOPICS[t].some((w) => lower.includes(w))) ?? "taste";
  const sentiment = NEGATIVE.some((w) => lower.includes(w)) ? "neg" : "pos";
  return {topic, sentiment};
}

// The model way: one request per review, with a schema.
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    topic: {enum: ["price", "taste", "service", "app"]},
    sentiment: {enum: ["pos", "neg"]},
  },
});
async function byModel(text) {
  return JSON.parse(await ask(`Label this café review with its topic (price, taste, service or app) and its sentiment (pos or neg).\n\n${text}`, {grammar}));
}

for (const [name, method] of [["rules", rules], ["model", byModel]]) {
  const start = performance.now();
  let right = 0;
  for (const [text, topic, sentiment] of REVIEWS) {
    const got = await method(text);
    right += got.topic === topic && got.sentiment === sentiment ? 1 : 0;
  }
  const ms = performance.now() - start;
  console.log(`${name.padEnd(5)} ${right} of ${REVIEWS.length} right, ${ms < 1000 ? "under a second" : `${Math.round(ms / 1000)} s`}`);
}
