import {ask} from "./lib/ask.mjs";

// A question whose answer is not in the documentation, asked twice.
const doc = "cafe.yml options:\n- port: the port the service listens on (default 8080).\n- menu_file: the path of the menu (default menu.json).\n- tax_rate: the tax added to every order (default 0.14).";
const question = "What does the retry_delay option do, and what is its default?";

console.log(`> ${question}\n${await ask(`${doc}\n\n${question}`)}\n`);
console.log(`> ${question} Answer only from the documentation above. If the answer is not there, say: Not in the documentation.`);
console.log(await ask(`${doc}\n\n${question}\nAnswer only from the documentation above. If the answer is not there, say: Not in the documentation.`));
