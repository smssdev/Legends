import {QUESTION, research} from "./lib/research.mjs";

// Sentences with no citation: the ones to check first.
export function uncited(response) {
  return response.content
    .filter((b) => b.type === "text" && b.text.trim() && !(b.citations ?? []).length)
    .map((b) => b.text.trim());
}

const found = uncited(await research(QUESTION));
if (!found.length) console.log("every sentence is cited");
for (const sentence of found) console.log(`no citation: ${sentence}`);
