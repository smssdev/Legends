import {ask, model} from "./lib/ask.mjs";

const orders = ["كوبان لاتيه كبيران لعمر", "سارة تريد شاياً صغيراً واحداً", "إسبريسو لعلي، صغير من فضلك", "منى: 3 أكواب شاي كبيرة", "لاتيه لحسن"];

// بلا قواعد، يُطلب من النموذج JSON وقد يعطيه وقد لا يعطيه.
// ومع قواعد مبنية من مخطط JSON، لا يستطيع أن ينتج غيره.
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    name: {type: "string"},
    drink: {enum: ["latte", "tea", "espresso"]},
    size: {enum: ["small", "large", "unknown"]},
    count: {type: "integer"},
  },
});

for (const [label, options] of [["no grammar", {}], ["schema", {grammar}]]) {
  console.log(`--- ${label}`);
  for (const order of orders) {
    const answer = await ask("اقرأ طلب القهوة هذا وأجب بـ JSON فقط، بالحقول name وdrink وsize وcount. الطلب: " + order, options);
    try {
      console.log(JSON.stringify(JSON.parse(answer)));
    } catch {
      console.log(`not JSON: ${JSON.stringify(answer.slice(0, 60))}...`);
    }
  }
}
