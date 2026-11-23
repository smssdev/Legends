import {ask, isRight, model} from "./lib/ask.mjs";
import {QUESTIONS} from "./data/questions.mjs";

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {correct: {type: "boolean"}, correctAnswer: {type: "string"}},
});
// اطلب من النموذج فحص جوابه هو، في محادثة جديدة.
for (const [question, expected] of QUESTIONS.slice(0, 8)) {
  const answer = await ask(`${question} أجب بالنتيجة فقط.`, {maxTokens: 30});
  const verdict = JSON.parse(await ask(`هذا سؤال وجواب. افحص الجواب بعناية. أجب بـ JSON: هل هو صحيح، وإن لم يكن، فما الجواب الصحيح.\n\n${question}\n${answer}`, {grammar, maxTokens: 200}));
  const right = isRight(answer, expected);
  const caught = !right && !verdict.correct;
  const label = right ? (verdict.correct ? "right, confirmed" : "right, DOUBTED") : caught ? "wrong, caught" : "WRONG, confirmed";
  console.log(`${label.padEnd(18)} ${answer.slice(0, 30)}`);
}
