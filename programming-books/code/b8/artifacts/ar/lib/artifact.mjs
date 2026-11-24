import Anthropic from "@anthropic-ai/sdk";
import fs from "node:fs";

const client = new Anthropic();

// The request for the artifact, and the message that reports a failed
// test.
export const REQUEST = "اصنع لي حاسبة بقشيش في صفحة HTML واحدة: حقل للفاتورة بالجنيه، وحقل لنسبة البقشيش، والبقشيش والإجمالي، يتحدثان وأنا أكتب.";
export const failed = (failure) => "فشل الاختبار: {failure}. أصلح الصفحة من فضلك.".replace("{failure}", failure);

export async function ask(messages) {
  const response = await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 8000,
    messages,
  });
  const blocks = response.content.filter((b) => b.type === "text");
  return blocks.map((b) => b.text).join("");
}

// The code blocks of a reply: ```lang ... ```
export function codeBlocks(text) {
  return [...text.matchAll(/```(\w*)\n([\s\S]*?)\n```/g)].map(([, lang, code]) => ({lang, code}));
}

export function save(file, code) {
  fs.mkdirSync("artifacts", {recursive: true});
  fs.writeFileSync(`artifacts/${file}`, code + "\n");
  console.log(`حُفظ artifacts/${file}: ${code.split("\n").length} سطراً`);
}
