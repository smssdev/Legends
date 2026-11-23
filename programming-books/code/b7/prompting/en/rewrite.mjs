import {ask} from "./lib/ask.mjs";
import {cases, score} from "./harness.mjs";

// Let the model rewrite a vague prompt, then score both on the same
// cases.
const vague = "Is this a bug, feature, question or billing?";
const better = await ask(`Rewrite this prompt for a language model so that it is clear and specific. Keep the task the same. Reply with the new prompt only.\n\n${vague}`);
console.log(`rewritten: ${better}\n`);
for (const prompt of [vague, better]) {
  console.log(`${await score(prompt, cases)} of ${cases.length}`);
}
