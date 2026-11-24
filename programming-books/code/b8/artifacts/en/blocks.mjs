import {ask, codeBlocks, save} from "./lib/artifact.mjs";

const EXTENSIONS = {html: "html", mermaid: "mmd", js: "js", css: "css", svg: "svg"};

// Every code block in a reply, saved to a file named for its language.
const reply = await ask([{role: "user", content: "Draw a diagram of how an order flows at the café, as Mermaid."}]);
for (const [i, {lang, code}] of codeBlocks(reply).entries()) {
  save(`block-${i + 1}.${EXTENSIONS[lang] ?? "txt"}`, code);
}
