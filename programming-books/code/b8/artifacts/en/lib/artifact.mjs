import Anthropic from "@anthropic-ai/sdk";
import fs from "node:fs";

const client = new Anthropic();

// The request for the artifact, and the message that reports a failed
// test.
export const REQUEST = "Make me a tip calculator as one HTML page: a field for the bill in EGP, a field for the tip percentage, and the tip and the total, updated as I type.";
export const failed = (failure) => "The test failed: {failure}. Please fix the page.".replace("{failure}", failure);

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
  console.log(`saved artifacts/${file}: ${code.split("\n").length} lines`);
}
