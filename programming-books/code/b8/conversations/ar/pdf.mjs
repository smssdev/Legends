import Anthropic from "@anthropic-ai/sdk";
import {block, text} from "./lib/files.mjs";

const client = new Anthropic();

const question = "ما التزامات المشتري؟ اذكر البند والصفحة لكل منها.";

// ملف PDF كتلة مستند: يقرأ Claude نصه وصفحاته.
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: [
    block("files/contract.pdf"),
    {type: "text", text: question},
  ]}],
});
console.log(text(response));
console.log(`--- ${response.usage.input_tokens} tokens in`);
