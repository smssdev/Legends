import {ask, codeBlocks, save} from "./lib/artifact.mjs";

const EXTENSIONS = {html: "html", mermaid: "mmd", js: "js", css: "css", svg: "svg"};

// كل كتلة كود في رد، تُحفظ في ملف مسمّى بلغتها.
const reply = await ask([{role: "user", content: "ارسم مخططاً لمسار الطلب في المقهى، بصيغة Mermaid."}]);
for (const [i, {lang, code}] of codeBlocks(reply).entries()) {
  save(`block-${i + 1}.${EXTENSIONS[lang] ?? "txt"}`, code);
}
