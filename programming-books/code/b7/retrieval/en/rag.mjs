import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";
import {DOCS} from "./data/docs.mjs";
import {ASKED} from "./data/questions.mjs";
import {embedder, nearest} from "./lib/embed.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});
async function ask(prompt) {
  const session = new LlamaChatSession({contextSequence: context.getSequence(), autoDisposeSequence: true});
  const answer = await session.prompt(prompt, {temperature: 0, maxTokens: 120});
  session.dispose();
  return answer.trim();
}
const embed = await embedder();
const docs = [...DOCS];

for (const [question, expected] of ASKED) {
  console.log(`> ${question}`);
  // Without the documents, the model answers from what it learned in
  // general.
  console.log(`  without: ${await ask(`Answer the customer's question in one sentence.\n\n${question}`)}`);
  // With the two closest documents, a rule, and citations.
  const found = await nearest(embed, docs, question, 2);
  const sources = found.map(({id, text}) => `[${id}] ${text}`).join("\n");
  const answer = await ask(`Answer the customer's question only from the documents below, in one sentence, and cite the document id in brackets, like [hours]. If the answer is not in the documents, say exactly: Not in our documents.\n\n${sources}\n\n${question}`);
  const ok = expected ? answer.toLowerCase().includes(expected) : answer.includes("Not in our documents");
  console.log(`  with ${found.map((f) => f.id).join(", ")}: ${answer}  ${ok ? "" : "<- CHECK"}`);
}
