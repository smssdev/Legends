import {ask, isRight, model} from "./lib/ask.mjs";
import {QUESTIONS} from "./data/questions.mjs";

// اطلب الجواب ودرجة ثقة، بمخطط.
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {answer: {type: "string"}, confidence: {type: "integer"}},
});
let wrongButSure = 0;
for (const [question, expected] of QUESTIONS) {
  const {answer, confidence} = JSON.parse(await ask(`أجب عن السؤال باختصار. وإن كنت لا تستطيع معرفة الجواب، فأجب unknown. وأعطِ أيضاً ثقتك بأن الجواب صحيح، من 0 إلى 100.\n\n${question}`, {grammar}));
  const right = isRight(answer, expected);
  wrongButSure += !right && confidence >= 90 ? 1 : 0;
  console.log(`${right ? "right" : "WRONG"} ${String(confidence).padStart(3)}%  ${answer.slice(0, 40)}`);
}
console.log(`--- wrong answers given with 90% confidence or more: ${wrongButSure}`);
