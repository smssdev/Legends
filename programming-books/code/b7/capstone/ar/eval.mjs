import {DOCS, EVAL} from "./data.mjs";
import {assistant} from "./lib/assistant.mjs";

// التقييم: هل يجد البحث المستند الصحيح، وهل الجواب صحيح ومستشهد، وهل
// يُقال الرفض بالضبط حين يجب؟
export async function evaluate(answer, cases = EVAL) {
  const score = {found: 0, right: 0, refusals: 0, problems: 0};
  const lines = [];
  for (const [question, doc, expected] of cases) {
    const result = await answer(question);
    const found = doc === null || result.sources.some((s) => s.id === doc);
    const words = [expected].flat();
    const right = expected === null ? result.refused : words.some((w) => result.text.toLowerCase().includes(w));
    score.found += found ? 1 : 0;
    score.right += right ? 1 : 0;
    score.refusals += expected === null && result.refused ? 1 : 0;
    score.problems += result.problems.length ? 1 : 0;
    lines.push(`${right ? "right" : "WRONG"} ${found ? "found" : "MISSED"} ${result.problems.join("; ").padEnd(14)} ${question}`);
  }
  return {score, lines};
}

if (process.argv[1].endsWith("eval.mjs")) {
  const {score, lines} = await evaluate(await assistant(DOCS));
  console.log(lines.join("\n"));
  console.log(`--- found ${score.found}/${EVAL.length}, right ${score.right}/${EVAL.length}, ` +
    `answers with a problem ${score.problems}`);
}
