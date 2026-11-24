import {QUESTION, render, research} from "./lib/research.mjs";

// اسأل مع البحث في الويب، واطبع الجواب بمصادره.
const response = await research(QUESTION);
const {text, sources} = render(response);
console.log(text);
const searches = response.usage.server_tool_use.web_search_requests;
console.log(`\nالمصادر (عمليات البحث: ${searches}):`);
sources.forEach((url, i) => console.log(`[${i + 1}] ${url}`));
