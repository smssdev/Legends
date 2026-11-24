import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const ask = {max_tokens: 200, messages: [{role: "user", content: "Hi"}]};

// Three mistakes every first program makes, and what the API answers.
const attempts = [
  ["a misspelled model", {...ask, model: "claude-opus-55"}],
  ["no max_tokens", {model: "claude-opus-5-5", messages: ask.messages}],
  ["thinking turned off", {...ask, model: "claude-opus-5-5", thinking: {type: "disabled"}}],
];
for (const [what, request] of attempts) {
  try {
    await client.messages.create(request);
    console.log(`${what}: ok`);
  } catch (error) {
    console.log(`${what}: ${error.status} ${error.constructor.name}\n  ${error.error?.error?.message}`);
  }
}
