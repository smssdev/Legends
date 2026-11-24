import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// Starting Claude's answer for it (prefill) is refused by current models.
try {
  await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 200,
    messages: [
      {role: "user", content: "Write the welcome text for our new website."},
      {role: "assistant", content: "Welcome to Bit Cafe,"},
    ],
  });
} catch (error) {
  console.log(`${error.status} ${error.constructor.name}\n  ${error.error?.error?.message}`);
}
