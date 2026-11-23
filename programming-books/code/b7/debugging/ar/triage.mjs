import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";

const log = fs.readFileSync("logs/week.log", "utf8");
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    first: {type: "string"},
    counts: {
      type: "array",
      items: {type: "object", properties: {message: {type: "string"}, times: {type: "integer"}}},
    },
  },
});
const answer = JSON.parse(await ask(`اقرأ هذا السجل. أجب بـ JSON: أول رسالة خطأ، وكم مرة تظهر كل رسالة خطأ مختلفة.\n\n${log}`, {grammar, maxTokens: 600}));

// النموذج يقرأ السجل؛ والبرنامج يعدّ الأشياء نفسها ليتحقق منه.
const errors = log.split("\n").filter((line) => line.includes(" ERROR "));
const actual = new Map();
for (const line of errors) {
  const message = line.split(" ERROR ")[1];
  actual.set(message, (actual.get(message) ?? 0) + 1);
}
console.log(`first: ${answer.first}`);
console.log(`       ${errors[0].split(" ERROR ")[1] === answer.first ? "right" : "WRONG"}`);
for (const {message, times} of answer.counts) {
  const real = actual.get(message) ?? 0;
  console.log(`${String(times).padStart(3)} said, ${String(real).padStart(3)} counted  ${message}`);
}
