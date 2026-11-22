import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 2048});

const ask =
  "Summarize the 2019 paper “Brewing Tokens” by Layla Hassan " +
  "in two sentences.";
const doubt = "If you are not sure the paper exists, say so.";
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
