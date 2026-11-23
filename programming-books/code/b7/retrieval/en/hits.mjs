import {DOCS} from "./data/docs.mjs";
import {QUESTIONS} from "./data/questions.mjs";
import {embedder, nearest} from "./lib/embed.mjs";

// Is the right document among the first k?
const embed = await embedder();
const docs = [...DOCS];
for (const k of [1, 2, 3]) {
  let hits = 0;
  for (const [question, expected] of QUESTIONS) {
    const found = await nearest(embed, docs, question, k);
    hits += found.some((f) => f.id === expected) ? 1 : 0;
  }
  console.log(`right document in the first ${k}: ${hits} of ${QUESTIONS.length}`);
}
