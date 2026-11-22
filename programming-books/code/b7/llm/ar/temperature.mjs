import {LlamaCompletion} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 512});
const completion = new LlamaCompletion({
  contextSequence: context.getSequence(),
});

// درجة الحرارة 0 تأخذ دائماً الرمز الأرجح؛ والدرجات الأعلى تسحب عشوائياً،
// فيتغير الجواب مع البذرة.
const request = "اسم قصير ولطيف لمقهى جديد:";
for (const temperature of [0, 1.2]) {
  console.log(`temperature ${temperature}:`);
  for (const seed of [1, 2, 3]) {
    const text = await completion.generateCompletion(request, {
      temperature,
      seed,
      maxTokens: 12,
    });
    console.log(`  seed ${seed}: ${text.trim().split("\n")[0]}`);
  }
}
