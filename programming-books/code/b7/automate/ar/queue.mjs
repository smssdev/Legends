import {ask, model} from "./lib/ask.mjs";
import {REVIEWS} from "./data/reviews.mjs";

const TOPICS = {
  price: ["غال", "سعر", "جنيه", "قيمة", "رخيص"],
  app: ["التطبيق", "طوابع", "توقف", "أدفع"],
  service: ["الباريستا", "انتظار", "يرحب", "لطيف", "الطاولة"],
  taste: ["اللاتيه", "الكيك", "الإسبريسو", "قهوة", "مر", "جاف", "طعم"],
};
const rule = (text) => Object.keys(TOPICS).find((t) => TOPICS[t].some((w) => text.toLowerCase().includes(w)));
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {topic: {enum: ["price", "taste", "service", "app"]}},
});

// حيث يختلف النموذج والقواعد، يقرر إنسان.
let agreed = 0;
const queue = [];
for (const [text, truth] of REVIEWS) {
  const {topic} = JSON.parse(await ask(`صنّف هذا التقييم لمقهى بموضوعه (price أو taste أو service أو app) وشعوره (pos أو neg).\n\n${text}`, {grammar}));
  if (topic === rule(text)) {
    agreed++;
    if (topic !== truth) {
      console.log(`agreed and WRONG: ${text}`);
    }
  } else {
    queue.push(`${text}  (model: ${topic}, rules: ${rule(text) ?? "none"}, truth: ${truth})`);
  }
}
console.log(`${agreed} decided automatically, ${queue.length} for a person:`);
queue.forEach((item) => console.log(`  ${item}`));
