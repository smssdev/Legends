import Anthropic from "@anthropic-ai/sdk";
import {loadProject} from "./lib/project.mjs";

const client = new Anthropic();

// How much of the context the knowledge takes, before any question.
for (const name of ["support", "marketing"]) {
  const {instructions, knowledge} = loadProject(name);
  const {input_tokens: size} = await client.messages.countTokens({
    model: "claude-opus-5-5",
    system: [{type: "text", text: instructions}, ...knowledge],
    messages: [{role: "user", content: "?"}],
  });
  const share = ((size / 1_000_000) * 100).toFixed(3);
  const files = `files: ${knowledge.length}`;
  console.log(`${name.padEnd(10)} ${files}, ${size} tokens: ${share}% of the context window`);
}
