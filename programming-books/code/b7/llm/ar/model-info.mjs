import {loadModel} from "./lib/model.mjs";

const model = await loadModel();

// ما يقوله ملف النموذج عن نفسه.
const {general, tokenizer} = model.fileInfo.metadata;
console.log(`name:            ${general.name}`);
console.log(`size label:      ${general.size_label} parameters`);
const gigabytes = (model.size / 1e9).toFixed(2);
console.log(`file:            ${gigabytes} GB (4-bit quantized)`);
console.log(`vocabulary:      ${tokenizer.ggml.tokens.length} tokens`);
console.log(`context window:  ${model.trainContextSize} tokens`);
