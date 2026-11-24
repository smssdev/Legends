import {QUESTION, render, research} from "./lib/research.mjs";

// Ask with web search, and print the answer with its sources.
const response = await research(QUESTION);
const {text, sources} = render(response);
console.log(text);
const searches = response.usage.server_tool_use.web_search_requests;
console.log(`\nSources (searches: ${searches}):`);
sources.forEach((url, i) => console.log(`[${i + 1}] ${url}`));
