import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const request = {
  model: "claude-opus-5-5",
  max_tokens: 500,
  messages: [{role: "user", content: "لخّص 4,000 مراجعة زبائن من الشهر الماضي."}],
};

// رد بطيء مقابل مهلة قصيرة، ثم مهلة أطول.
for (const timeout of [1000, 10000]) {
  const start = Date.now();
  try {
    const r = await client.messages.create(request, {timeout, maxRetries: 0});
    console.log(`timeout ${timeout} ms: ${r.content[0].text}`);
  } catch (error) {
    console.log(`timeout ${timeout} ms: ${error.constructor.name}`);
  }
  console.log(`  بعد ${Math.round((Date.now() - start) / 1000)} s`);
}
