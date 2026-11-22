import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 2048});
const options = {temperature: 0, maxTokens: 120};
const systemPrompt = "أنت مساعد موجز لمطوري JavaScript. أجب في سطرين على الأكثر.";

// النموذج لا يتذكر شيئاً: في كل دور تُرسل المحادثة كلها من جديد.
const sequence = context.getSequence();
const session = new LlamaChatSession({contextSequence: sequence, systemPrompt});
for (const question of ["كيف أقرأ ملف JSON في Node؟", "وكيف أكتب واحداً؟"]) {
  const answer = await session.prompt(question, options);
  // كم رمزاً تأخذ المحادثة الآن في السياق.
  console.log(`> ${question}\n${answer}\n[${sequence.nextTokenIndex} tokens]\n`);
}

sequence.dispose();
console.log("محادثة جديدة، سُئلت السؤال الثاني وحده:");
const fresh = new LlamaChatSession({
  contextSequence: context.getSequence(),
  systemPrompt,
});
console.log(`> وكيف أكتب واحداً؟\n${await fresh.prompt("وكيف أكتب واحداً؟", options)}`);
