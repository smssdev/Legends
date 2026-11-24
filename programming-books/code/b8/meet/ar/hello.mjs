import Anthropic from "@anthropic-ai/sdk";
import {cost} from "./lib/prices.mjs";

const client = new Anthropic();

// رسالة أولى: الجواب، ولماذا توقف، وكم كلّف.
const question = process.argv[2] ?? "عرّف بنفسك في ثلاث جمل.";
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: question}],
});
for (const block of response.content) {
  if (block.type === "text") console.log(block.text);
}
const {input_tokens, output_tokens} = response.usage;
const dollars = cost(response.model, response.usage).toFixed(6);
console.log(`--- stop: ${response.stop_reason}; ` +
  `tokens: ${input_tokens} in, ${output_tokens} out; cost: $${dollars}`);
