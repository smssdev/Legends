import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 6144});

// One question in a fresh conversation, at temperature 0.
export async function ask(prompt, options = {}) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
  });
  const answer = await session.prompt(prompt, {
    temperature: 0,
    maxTokens: options.maxTokens ?? 900,
    grammar: options.grammar,
  });
  session.dispose();
  return answer.trim();
}

// The first code block of an answer, or null when there is none.
export function codeOf(answer) {
  return answer.match(/```(?:\w+)?\n([\s\S]*?)```/)?.[1] ?? null;
}

export {model};
