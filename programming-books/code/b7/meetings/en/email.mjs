import {ask} from "./lib/ask.mjs";
import {newNumbers} from "./lib/facts.mjs";

const facts = "Facts: from the 1st of January the large latte costs 50 pounds instead of 45; every other price stays the same; the loyalty card starts on Monday the 8th of December in both branches.";
const email = await ask(`Write a short, friendly email from the café to its customers announcing these facts. At most 120 words. Use only the facts given.\n\n${facts}`, {maxTokens: 400});
console.log(email);

// Every number in the email must come from the facts it was given.
const words = email.split(/\s+/).length;
const invented = newNumbers(email, facts);
console.log(`--- ${words} words; numbers not in the facts: ${invented.join(", ") || "none"}`);
