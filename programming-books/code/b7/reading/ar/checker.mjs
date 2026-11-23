import {createRequire} from "node:module";
import {ask, model} from "./lib/ask.mjs";

const require = createRequire(import.meta.url);
const {calc} = require("./legacy/lib/calc.js");
const numbers = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "number"},
});

// تحقق من الشرح بأن تسأله هو، لا الكود، عن النتائج.
export async function checkExplanation(explanation, calls) {
  const written = calls.map(([o, d]) => `calc(${JSON.stringify(o)}, ${d})`);
  const prompt =
    `هذه قواعد دالة اسمها calc:\n${explanation}\n\n` +
    `باستخدام هذه القواعد وحدها، ماذا يعيد كل استدعاء؟ أجب بمصفوفة JSON من الأرقام فقط.\n${written.join("\n")}`;
  const predicted = JSON.parse(await ask(prompt, {grammar: numbers}));
  return calls.map(([o, d], i) => [predicted[i], calc(o, d)]);
}

const calls = [
  [{c: "STD", l: [{p: 4500, q: 2}]}, true],
  [{c: "STD", l: [{p: 2500, q: 10}]}, true],
  [{c: "STD", l: [{p: 2500, q: 10}]}, false],
  [{c: "VIP", l: [{p: 300, q: 1}]}, true],
  [{c: "STD", l: [{p: 10000, q: 2}]}, true],
  [{c: "vip", l: [{p: 4500, q: 2}]}, true],
];

const explanations = {
  vague: "تجمع الطلب وتعطي خصومات للطلبات الكبيرة ولعملاء VIP.",
  exact: "اجمع السعر مضروباً في الكمية لكل الأسطر. وإن كان d صحيحاً والمجموع أكبر من 20000، " + "فاطرح 10% مقرّبة للأسفل. ثم إن كان c هو VIP بالضبط، فاطرح 500. ولا تنزل تحت 0.",
};
for (const [name, text] of Object.entries(explanations)) {
  const pairs = await checkExplanation(text, calls);
  const right = pairs.filter(([p, a]) => p === a).length;
  console.log(`${name}: ${right} of ${calls.length}  ${JSON.stringify(pairs.map(([p]) => p))}`);
}
console.log(`actual: ${JSON.stringify(calls.map(([o, d]) => calc(o, d)))}`);
