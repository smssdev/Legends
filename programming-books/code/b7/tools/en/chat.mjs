import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 2048});
const options = {temperature: 0, maxTokens: 120};
const systemPrompt = "You are a concise assistant for JavaScript developers. Answer in at most two lines.";

// The model remembers nothing: every turn, the whole conversation is sent
// again.
const sequence = context.getSequence();
const session = new LlamaChatSession({contextSequence: sequence, systemPrompt});
for (const question of ["How do I read a JSON file in Node?", "And how do I write one?"]) {
  const answer = await session.prompt(question, options);
  // How many tokens the conversation now takes in the context.
  console.log(`> ${question}\n${answer}\n[${sequence.nextTokenIndex} tokens]\n`);
}

sequence.dispose();
console.log("A new conversation, asked only the second question:");
const fresh = new LlamaChatSession({
  contextSequence: context.getSequence(),
  systemPrompt,
});
console.log(`> And how do I write one?\n${await fresh.prompt("And how do I write one?", options)}`);
