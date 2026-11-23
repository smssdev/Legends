import {ask} from "./lib/ask.mjs";

// First the questions, before any specification.
const answer = await ask("A loyalty card in our café app: every 10th coffee is free.\n\nBefore anyone writes a specification for this idea, what questions must the café answer? List the ten most important, one line each.");
console.log(answer);

// The questions that matter for a loyalty card, as patterns; which did
// the model ask?
const matter = {
  "which drinks count": /which (drinks|items|products)|what (counts|qualifies)|eligible|count toward/i,
  "refunds and cancellations": /refund|cancel|return/i,
  "expiry": /expir|valid for|time limit|reset/i,
  "what the free drink can be": /free (drink|coffee|item).*(any|which|size|price|limit)|value of the free/i,
  "several branches": /branch|location|store|shop/i,
  "abuse and fraud": /fraud|abuse|cheat|misuse|share|transfer/i,
  "existing customers and past orders": /existing|past (orders|purchases)|retroactive|already/i,
};
console.log("--- the questions that matter");
for (const [name, pattern] of Object.entries(matter)) {
  console.log(`${pattern.test(answer) ? "asked " : "MISSED"} ${name}`);
}
