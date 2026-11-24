import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
export const QUESTION = "ماذا أعلنت جمعية البن المصرية عن أسعار البن هذا الشهر؟";

// شغّل البحث في الويب: يقرر Claude متى يبحث وعن ماذا.
export async function research(question, search = {}) {
  return client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 4000,
    tools: [
      {type: "web_search_20260209", name: "web_search", max_uses: 3, ...search},
    ],
    messages: [{role: "user", content: question}],
  });
}

// الجواب، برقم بعد كل ادعاء مستشهد، والمصادر في النهاية.
export function render(response) {
  const sources = [];
  let text = "";
  for (const block of response.content) {
    if (block.type !== "text") continue;
    text += block.text;
    for (const c of block.citations ?? []) {
      if (!sources.includes(c.url)) sources.push(c.url);
      text += `[${sources.indexOf(c.url) + 1}]`;
    }
  }
  return {text, sources};
}
