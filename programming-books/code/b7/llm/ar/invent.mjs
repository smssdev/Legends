import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 2048});

const ask =
  "لخّص في جملتين بحث «تخمير الرموز» " +
  "الذي نشرته ليلى حسن عام 2019.";
const doubt = "وإن لم تكن متأكداً من وجود البحث، فقل ذلك.";
const questions = [ask, `${ask} ${doubt}`];
for (const question of questions) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
  });
  const answer = await session.prompt(question, {
    temperature: 0,
    maxTokens: 120,
  });
  console.log(`> ${question}\n${answer}\n`);
  session.dispose();
}
