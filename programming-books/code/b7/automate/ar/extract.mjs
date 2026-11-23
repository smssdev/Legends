import {ask, model} from "./lib/ask.mjs";
import {NOTES} from "./data/notes.mjs";

// تعبير نمطي للملاحظات نفسها.
const WORDS = {"واحد": 1, "اثنان": 2, "ثلاثة": 3};
const NAMES = {"لاتيه": "latte", "شاي": "tea", "إسبريسو": "espresso", "صغير": "small", "كبير": "large"};
function byRegex(note) {
  const lower = note.toLowerCase();
  const drink = NAMES[lower.match(/لاتيه|شاي|إسبريسو/)?.[0]];
  const size = NAMES[lower.match(/صغير|كبير/)?.[0]] ?? "unknown";
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
  const {drink, size, count} = JSON.parse(await ask(`اقرأ ملاحظة طلب القهوة هذه. أجب بالمشروب (latte أو tea أو espresso)، والحجم (small أو large أو unknown)، والعدد.\n\n${note}`, {grammar}));
  return [drink, size, count];
}

const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
for (const [note, truth] of NOTES) {
  const [regex, modelAnswer] = [byRegex(note), await byModel(note)];
  console.log(`${same(regex, truth) ? "ok " : "BAD"} ${same(modelAnswer, truth) ? "ok " : "BAD"}  ${note}`);
}
console.log("(first column: the regular expression; second: the model)");
