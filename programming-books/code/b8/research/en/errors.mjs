import {research} from "./lib/research.mjs";

// A failed search comes back inside a successful response.
const question = "Compare bean prices in every country in Africa this month.";
const response = await research(question, {max_uses: 2});
for (const block of response.content) {
  if (block.type === "server_tool_use") console.log(`search: ${block.input.query}`);
  if (block.type !== "web_search_tool_result") continue;
  if (Array.isArray(block.content)) {
    console.log(`  ${block.content.length} results`);
  } else {
    console.log(`  search failed: ${block.content.error_code}`);
  }
}
console.log(`stop: ${response.stop_reason}`);
