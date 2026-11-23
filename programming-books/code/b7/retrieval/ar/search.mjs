import {DOCS} from "./data/docs.mjs";
import {QUESTIONS} from "./data/questions.mjs";
import {embedder, nearest} from "./lib/embed.mjs";

// أبسط بحث: المستند الذي يشارك السؤال أكثر الكلمات.
const words = (text) => new Set(text.toLowerCase().match(/[\p{L}\d]+/gu));
function byWords(question) {
  const q = words(question);
  const shared = DOCS.map(([id, text]) => [id, [...words(text)].filter((w) => q.has(w)).length]);
  return shared.sort((a, b) => b[1] - a[1])[0][0];
}

// نموذج المحادثة مستخدماً للتضمينات، ونموذج مصنوع لها.
const searches = {
  "shared words": async (question) => byWords(question),
  "chat model": await (async () => {
    const embed = await embedder("chat");
    const docs = [...DOCS];
    return async (question) => (await nearest(embed, docs, question, 1))[0].id;
  })(),
  "embedding model": await (async () => {
    const embed = await embedder("embedding");
    const docs = [...DOCS];
    return async (question) => (await nearest(embed, docs, question, 1))[0].id;
  })(),
};

for (const [name, search] of Object.entries(searches)) {
  let right = 0;
  const wrong = [];
  for (const [question, expected] of QUESTIONS) {
    const found = await search(question);
    if (found === expected) {
      right++;
    } else {
      wrong.push(`${expected}->${found}`);
    }
  }
  console.log(`${name.padEnd(16)} ${right} of ${QUESTIONS.length}  ${wrong.join(" ")}`);
}
