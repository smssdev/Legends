import Anthropic from "@anthropic-ai/sdk";
import {text} from "./lib/files.mjs";

const client = new Anthropic();
const messages = [];

const turns = [
  "My name is Mona and I run a café.",
  "Suggest a name for a new drink.",
  "What is my name?"
];

// The app keeps the conversation for you; a program sends it every time.
for (const question of turns) {
  messages.push({role: "user", content: question});
  const response = await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 1000,
    messages,
  });
  messages.push({role: "assistant", content: response.content});
  const used = response.usage.input_tokens;
  console.log(`> ${question}\n${text(response)}`);
  console.log(`  (turn ${messages.length / 2}: ${used} tokens in)`);
}
