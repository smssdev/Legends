import {DOCS} from "./data/docs.mjs";

// Every citation must name a real document, and the document must contain
// the answer's numbers.
export function checkCitations(answer) {
  const problems = [];
  const cited = [...answer.matchAll(/\[([\w-]+)\]/g)].map((m) => m[1]);
  const numbers = answer.match(/\d+/g) ?? [];
  for (const id of cited) {
    const doc = DOCS.find(([docId]) => docId === id);
    if (!doc) {
      problems.push(`[${id}] is not a document`);
    } else {
      for (const n of numbers.filter((n) => !doc[1].includes(n))) {
        problems.push(`${n} is not in [${id}]`);
      }
    }
  }
  return cited.length === 0 ? ["no citation"] : problems;
}

for (const answer of [
  "Oat milk costs 10 pounds extra [allergens].",
  "Oat milk costs 15 pounds extra [allergens].",
  "Gift cards are valid for one year [gift-cards].",
  "Yes, delivery takes about 30 minutes.",
]) {
  const problems = checkCitations(answer);
  console.log(`${problems.length ? "FAIL" : "ok  "} ${answer}  ${problems.join("; ")}`);
}
