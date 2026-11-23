import {ask} from "./lib/ask.mjs";

// الحساب يذهب إلى الكود؛ وكل شيء آخر إلى النموذج.
const ARITHMETIC = /^[\d\s.+\-*/×÷^()]+$/;
async function answer(question) {
  const expression = question.replace(/[^\d\s.+\-*/×÷^()]/g, "").trim();
  if (expression.length > 2 && ARITHMETIC.test(expression) && /\d\s*[-+*/×÷^]\s*\d/.test(expression)) {
    const js = expression.replaceAll("×", "*").replaceAll("÷", "/").replaceAll("^", "**");
    return {by: "code", result: String(Function(`return (${js});`)())};
  }
  return {by: "model", result: await ask(`${question} أجب باختصار.`, {maxTokens: 40})};
}

for (const question of ["كم يساوي 48213 × 7.35؟", "كم يساوي 2 ^ 20؟", "ما عاصمة مصر؟"]) {
  const {by, result} = await answer(question);
  console.log(`${by.padEnd(5)} ${question} -> ${result}`);
}
