import {research} from "./lib/research.mjs";

// البحث الفاشل يعود داخل رد ناجح.
const question = "قارن أسعار البن في كل دولة في أفريقيا هذا الشهر.";
const response = await research(question, {max_uses: 2});
for (const block of response.content) {
  if (block.type === "server_tool_use") console.log(`search: ${block.input.query}`);
  if (block.type !== "web_search_tool_result") continue;
  if (Array.isArray(block.content)) {
    console.log(`  ${block.content.length} results`);
  } else {
    console.log(`  فشل البحث: ${block.content.error_code}`);
  }
}
console.log(`stop: ${response.stop_reason}`);
