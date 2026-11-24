import Anthropic from "@anthropic-ai/sdk";
import {block, text} from "./lib/files.mjs";

const client = new Anthropic();

const question = "ماذا يُظهر هذا الرسم؟ أعطِ الأرقام.";

// الصورة كتلة محتوى، تُرسل بجانب السؤال.
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: [
    block("files/sales.png"),
    {type: "text", text: question},
  ]}],
});
console.log(text(response));
console.log(`--- ${response.usage.input_tokens} tokens in`);
