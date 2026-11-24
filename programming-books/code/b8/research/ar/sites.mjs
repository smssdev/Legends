import {QUESTION, research} from "./lib/research.mjs";

// كل نتيجة أعادها البحث: الموقع، والعمر، والعنوان.
const response = await research(QUESTION);
const results = response.content.filter((b) => b.type === "web_search_tool_result");
for (const block of results) {
  for (const r of block.content) {
    const site = new URL(r.url).hostname;
    console.log(`${site.padEnd(28)} ${r.page_age.padEnd(12)} ${r.title}`);
  }
}
