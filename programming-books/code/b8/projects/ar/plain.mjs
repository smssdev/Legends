import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// السؤال نفسه بلا مشروع: لا تعليمات، ولا معرفة.
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: "كم سعر اللاتيه بالورد؟"}],
});
console.log(response.content[0].text);
