import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});

// One question in a fresh conversation, at temperature 0.
export async function ask(prompt, system) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
    systemPrompt: system,
  });
  const answer = await session.prompt(prompt, {temperature: 0, maxTokens: 200});
  session.dispose();
  return answer.trim();
}

export {model};
