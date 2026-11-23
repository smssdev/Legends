import {ask, isRight, model} from "./lib/ask.mjs";
import {QUESTIONS} from "./data/questions.mjs";

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {correct: {type: "boolean"}, correctAnswer: {type: "string"}},
});
// Ask the model to check its own answer, in a new conversation.
for (const [question, expected] of QUESTIONS.slice(0, 8)) {
  const answer = await ask(`${question} Answer with the result only.`, {maxTokens: 30});
  const verdict = JSON.parse(await ask(`Here is a question and an answer. Check the answer carefully. Reply with JSON: is it correct, and if not, the correct answer.\n\n${question}\n${answer}`, {grammar, maxTokens: 200}));
  const right = isRight(answer, expected);
  const caught = !right && !verdict.correct;
  const label = right ? (verdict.correct ? "right, confirmed" : "right, DOUBTED") : caught ? "wrong, caught" : "WRONG, confirmed";
  console.log(`${label.padEnd(18)} ${answer.slice(0, 30)}`);
}
