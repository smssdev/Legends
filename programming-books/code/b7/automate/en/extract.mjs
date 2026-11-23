import {ask, model} from "./lib/ask.mjs";
import {NOTES} from "./data/notes.mjs";

// A regular expression for the same notes.
const WORDS = {one: 1, two: 2, three: 3};
const NAMES = {latte: "latte", tea: "tea", espresso: "espresso", small: "small", large: "large"};
function byRegex(note) {
  const lower = note.toLowerCase();
  const drink = NAMES[lower.match(/latte|tea|espresso/)?.[0]];
  const size = NAMES[lower.match(/small|large/)?.[0]] ?? "unknown";
  const digits = lower.match(/\d+/)?.[0];
  const word = Object.keys(WORDS).find((w) => lower.includes(w));
  return [drink, size, Number(digits ?? WORDS[word] ?? 1)];
}

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    drink: {enum: ["latte", "tea", "espresso"]},
    size: {enum: ["small", "large", "unknown"]},
    count: {type: "integer"},
  },
});
async function byModel(note) {
  const {drink, size, count} = JSON.parse(await ask(`Read this coffee order note. Reply with the drink (latte, tea or espresso), the size (small, large or unknown) and the count.\n\n${note}`, {grammar}));
  return [drink, size, count];
}

const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
for (const [note, truth] of NOTES) {
  const [regex, modelAnswer] = [byRegex(note), await byModel(note)];
  console.log(`${same(regex, truth) ? "ok " : "BAD"} ${same(modelAnswer, truth) ? "ok " : "BAD"}  ${note}`);
}
console.log("(first column: the regular expression; second: the model)");
