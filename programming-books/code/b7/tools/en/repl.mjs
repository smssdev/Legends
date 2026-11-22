import readline from "node:readline";
import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});
const sequence = context.getSequence();
const systemPrompt = "You are a concise assistant for JavaScript developers. Answer in at most two lines.";
const session = new LlamaChatSession({contextSequence: sequence, systemPrompt});
const initial = session.getChatHistory();

// A chat in the terminal: one session, so the conversation grows; /reset
// starts again.
const lines = readline.createInterface({input: process.stdin});
for await (const line of lines) {
  console.log(`> ${line}`);
  if (line === "/reset") {
    session.setChatHistory(initial);
    console.log("(conversation reset)\n");
    continue;
  }
  const answer = await session.prompt(line, {temperature: 0, maxTokens: 160});
  console.log(`${answer}\n`);
}
