import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// بدء جواب Claude عنه (prefill) ترفضه النماذج الحالية.
try {
  await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 200,
    messages: [
      {role: "user", content: "اكتب نص الترحيب لموقعنا الجديد."},
      {role: "assistant", content: "Welcome to Bit Cafe,"},
    ],
  });
} catch (error) {
  console.log(`${error.status} ${error.constructor.name}\n  ${error.error?.error?.message}`);
}
