import Anthropic from "@anthropic-ai/sdk";
import {text} from "./lib/files.mjs";

const client = new Anthropic();

// The same question, without the history.
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: "What is my name?"}],
});
console.log(text(response));
