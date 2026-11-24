import Anthropic from "@anthropic-ai/sdk";
import {text} from "./lib/files.mjs";

const client = new Anthropic();
const messages = [];

const turns = [
  "اسمي منى وأدير مقهى.",
  "اقترح اسماً لمشروب جديد.",
  "ما اسمي؟"
];

// التطبيق يحفظ المحادثة عنك؛ والبرنامج يرسلها في كل مرة.
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
  console.log(`  (الدور ${messages.length / 2}: ${used} tokens in)`);
}
