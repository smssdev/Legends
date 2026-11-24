import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// The answer as it is written: each piece printed as it arrives.
const stream = client.messages.stream({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: "Describe our rose latte for the menu board in two sentences."}],
});
let pieces = 0;
stream.on("text", (piece) => {
  process.stdout.write(pieces++ % 4 === 0 ? `|${piece}` : piece);
});
const message = await stream.finalMessage();
console.log(`\n--- ${pieces} pieces; stop: ${message.stop_reason}; ${message.usage.output_tokens} tokens out`);
