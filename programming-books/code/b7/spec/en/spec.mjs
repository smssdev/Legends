import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {criteria, vagueWords} from "./lib/vague.mjs";

const spec = await ask("A loyalty card in our café app: every 10th coffee is free.\nAnswers from the café: only paid hot drinks count, any size; stamps never expire; one card per account; a refunded drink removes its stamp; the free drink is any hot drink up to the price of a large latte; both branches share the card.\n\nWrite a short specification for this feature: a summary, the rules, and acceptance criteria written as Given / When / Then, one per line. Use only the answers given; do not add features.", {maxTokens: 900});
fs.writeFileSync("spec.md", spec);
console.log(spec);

// Words that sound like requirements but cannot be tested.
const vague = vagueWords(spec);
console.log(`--- vague words: ${[...vague].map(([w, n]) => `${w} (${n})`).join(", ") || "none"}`);

// Each acceptance criterion must have a Given, a When and a Then.
const found = criteria(spec);
console.log(`--- ${found.length} acceptance criteria, ${found.filter((c) => !c.ok).length} not in the form`);
