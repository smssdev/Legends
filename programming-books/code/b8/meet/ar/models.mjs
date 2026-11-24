import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// كل نموذج تتيحه لك الواجهة البرمجية، بحدوده.
for await (const model of client.models.list()) {
  const input = (model.max_input_tokens / 1000).toLocaleString("en-US");
  console.log(`${model.id.padEnd(18)} ${model.display_name.padEnd(18)} input ${input}K, output ${model.max_tokens / 1000}K`);
}
