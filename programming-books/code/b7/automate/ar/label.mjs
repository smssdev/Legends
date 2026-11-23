import {ask, model} from "./lib/ask.mjs";
import {REVIEWS} from "./data/reviews.mjs";

// الطريقة العادية: قواعد كلمات مفتاحية، كُتبت في خمس دقائق.
const TOPICS = {
  price: ["غال", "سعر", "جنيه", "قيمة", "رخيص"],
  app: ["التطبيق", "طوابع", "توقف", "أدفع"],
  service: ["الباريستا", "انتظار", "يرحب", "لطيف", "الطاولة"],
  taste: ["اللاتيه", "الكيك", "الإسبريسو", "قهوة", "مر", "جاف", "طعم"],
};
const NEGATIVE = ["جداً لكوب", "توقف", "باردة", "طويل", "جاف", "بلا طعم", "لم ", "متسخة", "مُرّ", "لا أصدق"];
function rules(text) {
  const lower = text.toLowerCase();
  const topic = Object.keys(TOPICS).find((t) => TOPICS[t].some((w) => lower.includes(w))) ?? "taste";
  const sentiment = NEGATIVE.some((w) => lower.includes(w)) ? "neg" : "pos";
  return {topic, sentiment};
}

// طريقة النموذج: طلب لكل تقييم، بمخطط.
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    topic: {enum: ["price", "taste", "service", "app"]},
    sentiment: {enum: ["pos", "neg"]},
  },
});
async function byModel(text) {
  return JSON.parse(await ask(`صنّف هذا التقييم لمقهى بموضوعه (price أو taste أو service أو app) وشعوره (pos أو neg).\n\n${text}`, {grammar}));
}

for (const [name, method] of [["rules", rules], ["model", byModel]]) {
  const start = performance.now();
  let right = 0;
  for (const [text, topic, sentiment] of REVIEWS) {
    const got = await method(text);
    right += got.topic === topic && got.sentiment === sentiment ? 1 : 0;
  }
  const ms = performance.now() - start;
  console.log(`${name.padEnd(5)} ${right} of ${REVIEWS.length} right, ${ms < 1000 ? "under a second" : `${Math.round(ms / 1000)} s`}`);
}
