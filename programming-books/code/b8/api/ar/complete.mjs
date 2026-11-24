import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const text = (r) => r.content.filter((b) => b.type === "text").map((b) => b.text).join("");

// اسأل حتى يكتمل الجواب، ثلاث مرات على الأكثر.
export async function complete(question, maxTokens) {
  const messages = [{role: "user", content: question}];
  let answer = "";
  for (let part = 1; part <= 3; part++) {
    const r = await client.messages.create({model: "claude-opus-5-5", max_tokens: maxTokens, messages});
    answer += (answer ? " " : "") + text(r);
    if (r.stop_reason !== "max_tokens") return {answer, parts: part};
    messages.push({role: "assistant", content: r.content}, {role: "user", content: "أكمل من حيث توقفت بالضبط."});
  }
  return {answer, parts: 3, cut: true};
}

const {answer, parts} = await complete("اكتب نص الترحيب لموقعنا الجديد.", 40);
console.log(`(${parts} أجزاء) ${answer}`);
