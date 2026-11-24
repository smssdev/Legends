import Anthropic from "@anthropic-ai/sdk";
import {block, text} from "./lib/files.mjs";

const client = new Anthropic();
const questions = {
  "sales.png": "ماذا يُظهر هذا الرسم؟ أعطِ الأرقام.",
  "receipt.png": "ما في هذا الإيصال؟",
};

// كل صورة في مجلد، ونوعها من امتدادها.
for (const [file, question] of Object.entries(questions)) {
  const content = [block(`files/${file}`), {type: "text", text: question}];
  const response = await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 500,
    messages: [{role: "user", content}],
  });
  console.log(`${file}: ${text(response)}\n`);
}
