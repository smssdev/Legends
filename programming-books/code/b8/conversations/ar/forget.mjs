import Anthropic from "@anthropic-ai/sdk";
import {text} from "./lib/files.mjs";

const client = new Anthropic();

// السؤال نفسه، بلا السجل.
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: "ما اسمي؟"}],
});
console.log(text(response));
