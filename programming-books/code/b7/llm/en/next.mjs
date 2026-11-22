import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 512});
const sequence = context.getSequence();

// Everything a model does is this: given the tokens so far, a probability
// for every possible next token.
const prompt = "The café sells coffee and";
const tokens = model.tokenize(prompt);
const options = {probabilities: true};
for await (const output of sequence.evaluateWithMetadata(tokens, options)) {
  const {probabilities} = output;
  console.log(`"${prompt}" ... 8 likely tokens, of ${probabilities.size}:`);
  for (const [token, probability] of [...probabilities].slice(0, 8)) {
    const piece = JSON.stringify(model.detokenize([token])).padEnd(14);
    const percent = (probability * 100).toFixed(1).padStart(5);
    const bar = "#".repeat(Math.round(probability * 40));
    console.log(`  ${piece} ${percent}%  ${bar}`);
  }
  break;
}
