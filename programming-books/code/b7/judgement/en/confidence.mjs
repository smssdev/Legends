import {ask, isRight, model} from "./lib/ask.mjs";
import {QUESTIONS} from "./data/questions.mjs";

// Ask for the answer and a confidence, with a schema.
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {answer: {type: "string"}, confidence: {type: "integer"}},
});
let wrongButSure = 0;
for (const [question, expected] of QUESTIONS) {
  const {answer, confidence} = JSON.parse(await ask(`Answer the question briefly. If you cannot know the answer, answer unknown. Also give your confidence that the answer is right, from 0 to 100.\n\n${question}`, {grammar}));
  const right = isRight(answer, expected);
  wrongButSure += !right && confidence >= 90 ? 1 : 0;
  console.log(`${right ? "right" : "WRONG"} ${String(confidence).padStart(3)}%  ${answer.slice(0, 40)}`);
}
console.log(`--- wrong answers given with 90% confidence or more: ${wrongButSure}`);
