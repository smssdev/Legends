import {ask, codeBlocks, REQUEST, save} from "./lib/artifact.mjs";

// Ask for an artifact, and save the code block from the reply.
const reply = await ask([{role: "user", content: REQUEST}]);
const [html] = codeBlocks(reply).filter((b) => b.lang === "html");
save("tip-v1.html", html.code);
