import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 512});
const sequence = context.getSequence();

// التوليد حلقة: تنبّأ، واختر، وأضف، وكرر. وهنا يُعرض كل اختيار مع
// احتماله.
const prompt = model.tokenize("المقهى يبيع القهوة و");
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
