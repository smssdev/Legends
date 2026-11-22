import {loadModel} from "./lib/model.mjs";

const model = await loadModel();

// An example price per million input tokens, to compare; real prices
// differ by provider and model.
const dollarsPerMillion = 3;

// Tokens are what you pay for and what fills the context: count them
// before you send.
const text = process.argv.slice(2).join(" ");
const tokens = model.tokenize(text).length;
const words = text.trim().split(/\s+/).length;
const perWord = (tokens / words).toFixed(2);
const price = ((tokens * dollarsPerMillion) / 1e6).toFixed(6);
console.log(`${words} words -> ${tokens} tokens (${perWord} per word)`);
console.log(`at $${dollarsPerMillion} per million tokens: $${price}`);
