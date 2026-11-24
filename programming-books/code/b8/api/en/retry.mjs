import Anthropic from "@anthropic-ai/sdk";

// The SDK retries a rate-limited request by itself; a fetch wrapper
// counts the attempts.
const statuses = [];
const counting = async (url, init) => {
  const response = await fetch(url, init);
  statuses.push(response.status);
  return response;
};

for (const [question, maxRetries] of [["Suggest a name for our new iced drink.", 2], ["List three ways to shorten the queue at lunch.", 0]]) {
  statuses.length = 0;
  const client = new Anthropic({fetch: counting, maxRetries});
  try {
    const r = await client.messages.create({
      model: "claude-opus-5-5",
      max_tokens: 200,
      messages: [{role: "user", content: question}],
    });
    console.log(r.content[0].text);
  } catch (error) {
    console.log(`${error.constructor.name}: ${error.status}`);
  }
  console.log(`  maxRetries ${maxRetries}, attempts: ${statuses.join(" → ")}`);
}
