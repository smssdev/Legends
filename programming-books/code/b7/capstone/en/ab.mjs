import {DOCS} from "./data.mjs";
import {assistant, QUOTE_FIRST, RULE} from "./lib/assistant.mjs";
import {evaluate} from "./eval.mjs";

// Two prompts, the same evaluation: decide by the numbers.
for (const [name, rule] of [["rule", RULE], ["quote first", QUOTE_FIRST]]) {
  const {score, lines} = await evaluate(await assistant(DOCS, {rule}));
  console.log(`${name.padEnd(12)} right ${score.right}/8, found ${score.found}/8, problems ${score.problems}`);
  lines.filter((line) => !line.startsWith("right found")).forEach((line) => console.log(`  ${line}`));
}
