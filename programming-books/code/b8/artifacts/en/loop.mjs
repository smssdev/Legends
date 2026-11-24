import {ask, codeBlocks, failed, REQUEST, save} from "./lib/artifact.mjs";
import {check} from "./check.mjs";

// Ask, test, send the failure back: at most three attempts, then a person
// looks.
const messages = [{role: "user", content: REQUEST}];
for (let attempt = 1; attempt <= 3; attempt++) {
  const reply = await ask(messages);
  messages.push({role: "assistant", content: reply});
  const [html] = codeBlocks(reply).filter((b) => b.lang === "html");
  save(`loop-${attempt}.html`, html.code);
  const {ok, failure} = await check(`artifacts/loop-${attempt}.html`);
  console.log(`attempt ${attempt}: ${ok ? "PASS" : `FAIL, ${failure}`}`);
  if (ok) process.exit(0);
  messages.push({role: "user", content: failed(failure)});
}
console.log("still failing: a person should look");
