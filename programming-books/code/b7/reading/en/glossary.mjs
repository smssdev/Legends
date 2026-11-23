import {ask, model, readProject} from "./lib/ask.mjs";

const project = readProject("legacy/lib") + readProject("legacy/data");
const text = {type: "string"};
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "object", properties: {term: text, inCode: text, meaning: text}},
  maxItems: 8,
});
const answer = await ask(`List the business terms this code uses (customer types, prices, discounts, limits), each with the exact word or value as it appears in the code and its meaning. Reply as JSON: [{\"term\": ..., \"inCode\": ..., \"meaning\": ...}]\n\n${project}`, {maxTokens: 1200, grammar});
const terms = JSON.parse(answer);

// Every term the model names must appear in the code, exactly as quoted.
for (const {term, inCode, meaning} of terms) {
  const found = project.includes(String(inCode));
  console.log(`${found ? "found  " : "MISSING"} ${String(inCode).padEnd(10)} ${term}: ${meaning}`);
}
