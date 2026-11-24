import {QUESTION, research} from "./lib/research.mjs";

// جمل بلا استشهاد: أول ما يُفحص.
export function uncited(response) {
  return response.content
    .filter((b) => b.type === "text" && b.text.trim() && !(b.citations ?? []).length)
    .map((b) => b.text.trim());
}

const found = uncited(await research(QUESTION));
if (!found.length) console.log("كل جملة مستشهدة");
for (const sentence of found) console.log(`بلا استشهاد: ${sentence}`);
