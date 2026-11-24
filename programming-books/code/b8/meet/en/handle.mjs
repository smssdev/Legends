import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// What to tell the developer for each kind of error.
export function advice(error) {
  if (error instanceof Anthropic.APIConnectionError) return "No connection: check the network and ANTHROPIC_BASE_URL.";
  if (error instanceof Anthropic.AuthenticationError) return "Check ANTHROPIC_API_KEY: missing, mistyped or revoked.";
  if (error instanceof Anthropic.NotFoundError) return "Check the model name against GET /v1/models.";
  if (error instanceof Anthropic.RateLimitError) return "Too many requests: wait as long as retry-after says, then retry.";
  if (error instanceof Anthropic.BadRequestError) return "Fix the request: read the message, it names the field.";
  if (error instanceof Anthropic.InternalServerError) return "A problem on the API's side: retry with backoff.";
  throw error;
}

const cases = [
  ["claude-opus-55", {}],
  ["claude-opus-5-5", {apiKey: "wrong-key"}],
  ["claude-opus-5-5", {baseURL: "http://127.0.0.1:9"}],
];
for (const [model, options] of cases) {
  const c = new Anthropic({maxRetries: 0, ...options});
  try {
    await c.messages.create({model, max_tokens: 100, messages: [{role: "user", content: "Hi"}]});
  } catch (error) {
    console.log(`${error.constructor.name.padEnd(20)} ${advice(error)}`);
  }
}
