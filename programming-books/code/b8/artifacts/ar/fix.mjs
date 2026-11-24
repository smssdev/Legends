import {ask, codeBlocks, failed, REQUEST, save} from "./lib/artifact.mjs";
import {check} from "./check.mjs";

// أعد الإخفاق إلى المحادثة نفسها، واحفظ النسخة الجديدة.
const messages = [{role: "user", content: REQUEST}];
messages.push({role: "assistant", content: await ask(messages)});
const {failure} = await check("artifacts/tip-v1.html");
messages.push({role: "user", content: failed(failure)});
const reply = await ask(messages);
const [html] = codeBlocks(reply).filter((b) => b.lang === "html");
save("tip-v2.html", html.code);
