import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";

// The same request three times at temperature 0.7: how much do the
// estimates move?
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "object", properties: {title: {type: "string"}, estimate: {type: "number"}}},
  minItems: 3,
  maxItems: 10,
});
const spec = fs.readFileSync("spec.md", "utf8");
for (const seed of [1, 2, 3]) {
  const answer = await ask(`Break this specification into development tasks for a small team. Reply with JSON: a list of tasks, each with id (T1, T2...), title, estimate in hours, and dependsOn (a list of ids).\n\n${spec}`, {grammar, temperature: 0.7, seed, maxTokens: 1000});
  const tasks = JSON.parse(answer);
  const total = tasks.reduce((sum, t) => sum + t.estimate, 0);
  console.log(`seed ${seed}: ${tasks.length} tasks, ${Math.round(total * 10) / 10} hours`);
}
