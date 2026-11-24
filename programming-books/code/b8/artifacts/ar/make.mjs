import {ask, codeBlocks, REQUEST, save} from "./lib/artifact.mjs";

// اطلب artifact، واحفظ كتلة الكود من الرد.
const reply = await ask([{role: "user", content: REQUEST}]);
const [html] = codeBlocks(reply).filter((b) => b.lang === "html");
save("tip-v1.html", html.code);
