import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 2048});

// One question in a fresh conversation.
export async function ask(prompt, options = {}) {
  const session = new LlamaChatSession({contextSequence: context.getSequence(), autoDisposeSequence: true});
  const answer = await session.prompt(prompt, {
    temperature: options.temperature ?? 0,
    seed: options.seed,
    maxTokens: options.maxTokens ?? 120,
    grammar: options.grammar,
  });
  session.dispose();
  return answer.trim();
}

// Right if the expected answer appears, ignoring case, spaces and
// thousands separators.
export function isRight(answer, expected) {
  const clean = (s) => String(s).toLowerCase().replace(/[\s,]/g, "");
  return clean(answer).includes(clean(expected));
}

export {model};
