import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const ask = {max_tokens: 200, messages: [{role: "user", content: "Hi"}]};

// ثلاثة أخطاء يقع فيها كل برنامج أول، وبماذا تجيب الواجهة البرمجية.
const attempts = [
  ["اسم نموذج فيه خطأ", {...ask, model: "claude-opus-55"}],
  ["بلا max_tokens", {model: "claude-opus-5-5", messages: ask.messages}],
  ["إيقاف التفكير", {...ask, model: "claude-opus-5-5", thinking: {type: "disabled"}}],
];
for (const [what, request] of attempts) {
  try {
    await client.messages.create(request);
    console.log(`${what}: ok`);
  } catch (error) {
    console.log(`${what}: ${error.status} ${error.constructor.name}\n  ${error.error?.error?.message}`);
  }
}
