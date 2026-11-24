import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// The same question with no project: no instructions, no knowledge.
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: "How much is the rose latte?"}],
});
console.log(response.content[0].text);
