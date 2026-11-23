import {ask} from "./lib/ask.mjs";
import {numbers} from "./lib/facts.mjs";

const facts = "Facts: from the 1st of January the large latte costs 50 pounds instead of 45; every other price stays the same; the loyalty card starts on Monday the 8th of December in both branches.";
const friendly = await ask(`Write a short, friendly email from the café to its customers announcing these facts. At most 120 words. Use only the facts given.\n\n${facts}`, {maxTokens: 400});
const formal = await ask(`Rewrite this email in a more formal tone, for a corporate customer. Keep every fact.\n\n${friendly}`, {maxTokens: 400});
console.log(formal);

const before = numbers(friendly);
const after = numbers(formal);
const lost = [...before].filter((n) => !after.has(n));
const added = [...after].filter((n) => !before.has(n));
console.log(`--- numbers lost: ${lost.join(", ") || "none"}; added: ${added.join(", ") || "none"}`);
