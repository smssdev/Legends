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
  // بلا المستندات، يجيب النموذج مما تعلّمه عموماً.
  console.log(`  without: ${await ask(`أجب عن سؤال العميل في جملة واحدة.\n\n${question}`)}`);
  // مع أقرب مستندين، وقاعدة، واستشهادات.
  const found = await nearest(embed, docs, question, 2);
  const sources = found.map(({id, text}) => `[${id}] ${text}`).join("\n");
  const answer = await ask(`أجب عن سؤال العميل من المستندات أدناه فقط، في جملة واحدة، واذكر معرّف المستند بين قوسين معقوفين، مثل [hours]. وإن لم يكن الجواب في المستندات، فقل بالضبط: ليس في مستنداتنا.\n\n${sources}\n\n${question}`);
  const ok = expected ? answer.toLowerCase().includes(expected) : answer.includes("ليس في مستنداتنا");
  console.log(`  with ${found.map((f) => f.id).join(", ")}: ${answer}  ${ok ? "" : "<- CHECK"}`);
}
