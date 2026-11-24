import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const text = (r) => r.content.filter((b) => b.type === "text").map((b) => b.text).join("");

// جواب قُطع عند max_tokens، يُكمل والنص المقطوع في السجل.
const messages = [{role: "user", content: "اكتب نص الترحيب لموقعنا الجديد."}];
const first = await client.messages.create({model: "claude-opus-5-5", max_tokens: 40, messages});
console.log(`[${first.stop_reason}] ${text(first)}`);

messages.push({role: "assistant", content: first.content});
messages.push({role: "user", content: "أكمل من حيث توقفت بالضبط."});
const rest = await client.messages.create({model: "claude-opus-5-5", max_tokens: 1000, messages});
console.log(`[${rest.stop_reason}] ${text(rest)}`);
