import {loadModel} from "./lib/model.mjs";

const model = await loadModel();

// سعر مثالي لكل مليون رمز مُدخل، للمقارنة؛ والأسعار الحقيقية تختلف بين
// المزوّدين والنماذج.
const dollarsPerMillion = 3;

// الرموز هي ما تدفع ثمنه وما يملأ السياق: عُدّها قبل أن ترسل.
const text = process.argv.slice(2).join(" ");
const tokens = model.tokenize(text).length;
const words = text.trim().split(/\s+/).length;
const perWord = (tokens / words).toFixed(2);
const price = ((tokens * dollarsPerMillion) / 1e6).toFixed(6);
console.log(`${words} words -> ${tokens} tokens (${perWord} per word)`);
console.log(`at $${dollarsPerMillion} per million tokens: $${price}`);
