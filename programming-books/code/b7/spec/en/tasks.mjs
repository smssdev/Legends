import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";
import {checkTasks} from "./lib/graph.mjs";

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {
    type: "object",
    properties: {
      id: {type: "string"},
      title: {type: "string"},
      estimate: {type: "number"},
      dependsOn: {type: "array", items: {type: "string"}},
    },
  },
  minItems: 3,
  maxItems: 12,
});
const spec = fs.readFileSync("spec.md", "utf8");
const tasks = JSON.parse(await ask(`Break this specification into development tasks for a small team. Reply with JSON: a list of tasks, each with id (T1, T2...), title, estimate in hours, and dependsOn (a list of ids).\n\n${spec}`, {grammar, maxTokens: 1200}));
fs.writeFileSync("tasks.json", JSON.stringify(tasks, null, 2));
for (const {id, title, estimate, dependsOn} of tasks) {
  console.log(`${id.padEnd(4)} ${String(estimate).padStart(4)} h  ${title}  [${dependsOn.join(", ")}]`);
}
const total = tasks.reduce((sum, t) => sum + t.estimate, 0);
console.log(`total: ${Math.round(total * 10) / 10} hours`);

// Every dependency must exist, and there must be no cycle.
const {problems, order} = checkTasks(tasks);
console.log(problems.length ? problems.join("\n") : "dependencies: ok");
console.log(`an order: ${order.join(" ")}`);
