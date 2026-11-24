import Anthropic from "@anthropic-ai/sdk";
import fs from "node:fs";
import path from "node:path";

const client = new Anthropic();
const read = (...parts) => fs.readFileSync(path.join(...parts), "utf8");

// المشروع: تعليمات لكل محادثة، ومعرفة، موسومة للذاكرة المؤقتة.
export function loadProject(folder) {
  const instructions = read(folder, "instructions.md");
  const dir = path.join(folder, "knowledge");
  const knowledge = fs.readdirSync(dir).sort().map((name) => ({
    type: "text",
    text: `<document name="${name}">\n${read(dir, name)}</document>`,
  }));
  knowledge.at(-1).cache_control = {type: "ephemeral"};
  return {instructions, knowledge};
}

export async function chat(project, question) {
  return client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 1000,
    system: [{type: "text", text: project.instructions}, ...project.knowledge],
    messages: [{role: "user", content: question}],
  });
}

export function text(response) {
  const blocks = response.content.filter((b) => b.type === "text");
  return blocks.map((b) => b.text).join("");
}
