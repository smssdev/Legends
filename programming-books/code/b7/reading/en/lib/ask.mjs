import fs from "node:fs";
import path from "node:path";
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
    maxTokens: options.maxTokens ?? 400,
    grammar: options.grammar,
  });
  session.dispose();
  return answer.trim();
}

export {model};

// Every file of a folder as "--- path" followed by its text.
export function readProject(folder) {
  return fs
    .readdirSync(folder, {recursive: true})
    .map((name) => path.join(folder, name))
    .filter((file) => fs.statSync(file).isFile())
    .sort()
    .map((file) => `--- ${file}\n${fs.readFileSync(file, "utf8")}`)
    .join("\n");
}
