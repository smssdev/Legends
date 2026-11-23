import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";

// الطلب نفسه ثلاث مرات بدرجة 0.7: كم تتحرك التقديرات؟
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "object", properties: {title: {type: "string"}, estimate: {type: "number"}}},
  minItems: 3,
  maxItems: 10,
});
const spec = fs.readFileSync("spec.md", "utf8");
for (const seed of [1, 2, 3]) {
  const answer = await ask(`قسّم هذه المواصفات إلى مهام تطوير لفريق صغير. أجب بـ JSON: قائمة مهام، لكل منها id (T1، T2...)، وtitle، وestimate بالساعات، وdependsOn (قائمة معرّفات).\n\n${spec}`, {grammar, temperature: 0.7, seed, maxTokens: 1000});
  const tasks = JSON.parse(answer);
  const total = tasks.reduce((sum, t) => sum + t.estimate, 0);
  console.log(`seed ${seed}: ${tasks.length} tasks, ${total} hours`);
}
