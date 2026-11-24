import Anthropic from "@anthropic-ai/sdk";
import {block, text} from "./lib/files.mjs";

const client = new Anthropic();
const questions = {
  "sales.png": "What does this chart show? Give the numbers.",
  "receipt.png": "What is on this receipt?",
};

// Every image in a folder, with the media type from its extension.
for (const [file, question] of Object.entries(questions)) {
  const content = [block(`files/${file}`), {type: "text", text: question}];
  const response = await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 500,
    messages: [{role: "user", content}],
  });
  console.log(`${file}: ${text(response)}\n`);
}
