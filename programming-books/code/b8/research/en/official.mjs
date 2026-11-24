import {QUESTION, render, research} from "./lib/research.mjs";

// The same question, searching only the sites the team trusts.
const trusted = ["coffee-association.example", "news.example"];
const response = await research(QUESTION, {allowed_domains: trusted});
const {text, sources} = render(response);
console.log(text);
sources.forEach((url, i) => console.log(`[${i + 1}] ${url}`));
