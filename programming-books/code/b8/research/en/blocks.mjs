import {QUESTION, research} from "./lib/research.mjs";

const response = await research(QUESTION);
for (const block of response.content) {
  const detail = block.type === "server_tool_use" ? JSON.stringify(block.input)
    : block.type === "web_search_tool_result" ? `${block.content.length} results`
    : `${block.text.length} chars, ${(block.citations ?? []).length} citations`;
  console.log(`${block.type.padEnd(22)} ${detail}`);
}
