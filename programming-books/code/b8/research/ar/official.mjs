import {QUESTION, render, research} from "./lib/research.mjs";

// السؤال نفسه، والبحث في المواقع التي يثق بها الفريق فقط.
const trusted = ["coffee-association.example", "news.example"];
const response = await research(QUESTION, {allowed_domains: trusted});
const {text, sources} = render(response);
console.log(text);
sources.forEach((url, i) => console.log(`[${i + 1}] ${url}`));
