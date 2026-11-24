import {DOCS, EVAL, MORE_WORDS} from "./data.mjs";
import {assistant, QUOTE_FIRST, RULE} from "./lib/assistant.mjs";
import {evaluate} from "./eval.mjs";

// Every answer marked WRONG was read by a person: each was right. The
// words a right answer may use, widened, and the two prompts measured
// again.
const fair = EVAL.map(([q, doc, word]) => [q, doc, word === null ? null : [word, ...(MORE_WORDS[doc] ?? [])]]);
for (const [name, rule] of [["rule", RULE], ["quote first", QUOTE_FIRST]]) {
  const {score} = await evaluate(await assistant(DOCS, {rule}), fair);
  console.log(`${name.padEnd(12)} right ${score.right}/8, found ${score.found}/8, problems ${score.problems}`);
}
