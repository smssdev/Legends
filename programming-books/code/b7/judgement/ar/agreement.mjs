import {ask, isRight} from "./lib/ask.mjs";
import {QUESTIONS} from "./data/questions.mjs";

// خمس عيّنات بدرجة 0.8: هل تتفق؟
for (const [question, expected] of QUESTIONS.slice(0, 8)) {
  const answers = [];
  for (const seed of [1, 2, 3, 4, 5]) {
    answers.push(await ask(`${question} أجب بالنتيجة فقط.`, {temperature: 0.8, seed, maxTokens: 30}));
  }
  const counts = new Map();
  answers.forEach((a) => counts.set(a, (counts.get(a) ?? 0) + 1));
  const [top, n] = [...counts].sort((a, b) => b[1] - a[1])[0];
  const right = isRight(top, expected);
  console.log(`${n}/5 agree  ${right ? "right" : "WRONG"}  ${top.slice(0, 40)}`);
}
