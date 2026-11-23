import {ask} from "./lib/ask.mjs";

// Arithmetic goes to code; everything else to the model.
const ARITHMETIC = /^[\d\s.+\-*/×÷^()]+$/;
async function answer(question) {
  const expression = question.replace(/[^\d\s.+\-*/×÷^()]/g, "").trim();
  if (expression.length > 2 && ARITHMETIC.test(expression) && /\d\s*[-+*/×÷^]\s*\d/.test(expression)) {
    const js = expression.replaceAll("×", "*").replaceAll("÷", "/").replaceAll("^", "**");
    return {by: "code", result: String(Function(`return (${js});`)())};
  }
  return {by: "model", result: await ask(`${question} Answer briefly.`, {maxTokens: 40})};
}

for (const question of ["What is 48213 × 7.35?", "What is 2 ^ 20?", "What is the capital of Egypt?"]) {
  const {by, result} = await answer(question);
  console.log(`${by.padEnd(5)} ${question} -> ${result}`);
}
