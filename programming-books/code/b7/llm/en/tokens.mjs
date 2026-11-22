import {loadModel} from "./lib/model.mjs";

const model = await loadModel();

// The same sentence in two languages, and how the model cuts each into
// tokens.
const sentences = [
  "The café opens at 8:30 and closes at 22:00.",
  "يفتح المقهى في 8:30 ويغلق في 22:00.",
];
for (const sentence of sentences) {
  const tokens = model.tokenize(sentence);
  const pieces = tokens.map((token) => model.detokenize([token]));
  const words = sentence.split(" ").length;
  const size = `${sentence.length} characters, ${tokens.length} tokens`;
  console.log(`${words} words, ${size}`);
  console.log("  " + pieces.map((piece) => `[${piece}]`).join(""));
}
