import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 512});
const sequence = context.getSequence();

// Generation is a loop: predict, choose, append, repeat. Here each choice
// is shown with its probability.
const prompt = model.tokenize("The café sells coffee and");
let step = 0;
const options = {confidence: true};
for await (const output of sequence.evaluateWithMetadata(prompt, options)) {
  const piece = JSON.stringify(model.detokenize([output.token])).padEnd(14);
  const percent = (output.confidence * 100).toFixed(1);
  console.log(`step ${++step}: ${piece} ${percent}%`);
  if (step === 8) {
    break;
  }
}
