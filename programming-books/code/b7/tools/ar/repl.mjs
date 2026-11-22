import readline from "node:readline";
import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});
const sequence = context.getSequence();
const systemPrompt = "أنت مساعد موجز لمطوري JavaScript. أجب في سطرين على الأكثر.";
const session = new LlamaChatSession({contextSequence: sequence, systemPrompt});
const initial = session.getChatHistory();

// محادثة في الطرفية: جلسة واحدة، فتكبر المحادثة؛ و/reset تبدأ من جديد.
const lines = readline.createInterface({input: process.stdin});
for await (const line of lines) {
  console.log(`> ${line}`);
  if (line === "/reset") {
    session.setChatHistory(initial);
    console.log("(بدأت المحادثة من جديد)\n");
    continue;
  }
  const answer = await session.prompt(line, {temperature: 0, maxTokens: 160});
  console.log(`${answer}\n`);
}
