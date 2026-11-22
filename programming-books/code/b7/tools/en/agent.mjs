import fs from "node:fs";
import {LlamaChatSession, defineChatSessionFunction} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});

// Tools the agent may call. The model chooses; this code runs them and
// returns the result.
const functions = {
  listFiles: defineChatSessionFunction({
    description: "List the files of the project",
    handler() {
      return show("listFiles", {}, fs.readdirSync("cafe", {recursive: true}));
    },
  }),
  readFile: defineChatSessionFunction({
    description: "Read one file of the project",
    params: {type: "object", properties: {path: {type: "string"}}},
    handler({path}) {
      return show("readFile", {path}, fs.readFileSync(`cafe/${path}`, "utf8"));
    },
  }),
};

// Show every call, so we can see what the agent did, not only what it
// said.
function show(name, params, result) {
  console.log(`[tool] ${name}(${JSON.stringify(params)})`);
  return result;
}

// First the question alone; then a system prompt that says what the tools
// are for, and a question that says it is about the project.
const tries = [
  [undefined, "What does a large latte cost, and which file sets that price?"],
  ["You work inside a software project. Use the tools to look at its files before you answer.", "In this project, what does a large latte cost, and which file sets that price?"],
];
for (const [systemPrompt, question] of tries) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
    systemPrompt,
  });
  console.log(`--- system prompt: ${systemPrompt ?? "(default)"}`);
  console.log(`> ${question}`);
  console.log(await session.prompt(question, {functions, temperature: 0}));
  session.dispose();
}
