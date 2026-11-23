import {ask} from "./lib/ask.mjs";
import {redact, restore} from "./lib/pii.mjs";

const message = "Hi, this is Mona Hassan (mona.hassan@example.com, 0101 234 5678). My card 4111 1111 1111 1111 was charged twice for order 41.";
const {safe, found} = redact(message);
console.log(`what leaves the machine:\n  ${safe}`);
const summary = await ask(`Summarise this customer message in one sentence for the support team, keeping the placeholders exactly as they are.\n\n${safe}`);
console.log(`the answer that comes back:\n  ${summary}`);
console.log(`shown to the support team:\n  ${restore(summary, found)}`);
