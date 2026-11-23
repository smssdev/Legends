import {ask} from "./lib/ask.mjs";

// Five parts of a good prompt. Leave out the ones you do not need.
export function buildPrompt({context, task, format, rules}) {
  return [context, task, format, rules]
    .filter(Boolean)
    .join("\n\n");
}

const prompt = buildPrompt({
  context: "The team writes Node 22 code with ES modules and no TypeScript.",
  task: "Explain what this line does: const unique = [...new Set(items)];",
  format: "One sentence, then one example with input and output.",
  rules: "Do not suggest other ways to write it.",
});
const system = "You are a senior JavaScript developer who reviews code for a small team.";
console.log(`[system] ${system}\n${prompt}\n---`);
console.log(await ask(prompt, {system}));
