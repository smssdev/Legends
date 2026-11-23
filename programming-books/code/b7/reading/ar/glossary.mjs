import {ask, model, readProject} from "./lib/ask.mjs";

const project = readProject("legacy/lib") + readProject("legacy/data");
const text = {type: "string"};
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "object", properties: {term: text, inCode: text, meaning: text}},
  maxItems: 8,
});
const answer = await ask(`اسرد مصطلحات العمل التي يستخدمها هذا الكود (أنواع العملاء، والأسعار، والخصومات، والحدود)، كلٌّ مع الكلمة أو القيمة كما تظهر في الكود بالضبط ومعناها. أجب بـ JSON: [{\"term\": ..., \"inCode\": ..., \"meaning\": ...}]\n\n${project}`, {maxTokens: 1200, grammar});
const terms = JSON.parse(answer);

// كل مصطلح يسميه النموذج يجب أن يظهر في الكود، كما اقتُبس بالضبط.
for (const {term, inCode, meaning} of terms) {
  const found = project.includes(String(inCode));
  console.log(`${found ? "found  " : "MISSING"} ${String(inCode).padEnd(10)} ${term}: ${meaning}`);
}
