import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 6144});

// One question in a fresh conversation (temperature 0 unless asked).
export async function ask(prompt, options = {}) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
  });
  const answer = await session.prompt(prompt, {
    temperature: options.temperature ?? 0,
    seed: options.seed,
    maxTokens: options.maxTokens ?? 700,
    grammar: options.grammar,
  });
  session.dispose();
  return answer.trim();
}

export {model};
