import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const text = (r) => r.content.filter((b) => b.type === "text").map((b) => b.text).join("");

// An answer cut off at max_tokens, continued with the cut text in the
// history.
const messages = [{role: "user", content: "Write the welcome text for our new website."}];
const first = await client.messages.create({model: "claude-opus-5-5", max_tokens: 40, messages});
console.log(`[${first.stop_reason}] ${text(first)}`);

messages.push({role: "assistant", content: first.content});
messages.push({role: "user", content: "Continue exactly where you stopped."});
const rest = await client.messages.create({model: "claude-opus-5-5", max_tokens: 1000, messages});
console.log(`[${rest.stop_reason}] ${text(rest)}`);
