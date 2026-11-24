import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// الجواب وهو يُكتب: كل قطعة تُطبع لحظة وصولها.
const stream = client.messages.stream({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: "صِف اللاتيه بالورد للوحة القائمة في جملتين."}],
});
let pieces = 0;
stream.on("text", (piece) => {
  process.stdout.write(pieces++ % 4 === 0 ? `|${piece}` : piece);
});
const message = await stream.finalMessage();
console.log(`\n--- ${pieces} قطعة; stop: ${message.stop_reason}; ${message.usage.output_tokens} tokens out`);
