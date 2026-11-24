import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";
import {index} from "./embed.mjs";
import {audit, citations, secrets} from "./checks.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});

export const RULE =
  "أنت مساعد فريق تطوير صغير. أجب عن السؤال في جملة واحدة، من " +
  "المستندات أدناه فقط، واذكر معرّف المستند بين قوسين معقوفين، مثل " +
  "[deploy]. وإن لم يكن الجواب في المستندات، فقل بالضبط: ليس في " +
  "مستنداتنا.";

// القاعدة التي توصي بها أدلة كثيرة: اقتبس المصدر، ثم أجب.
export const QUOTE_FIRST =
  "أنت مساعد فريق تطوير صغير. اقتبس أولاً، بين علامتي تنصيص، جملة " +
  "المستندات التي تجيب عن السؤال؛ ثم أجب في جملة واحدة واذكر معرّف " +
  "المستند بين قوسين معقوفين، مثل [deploy]. وإن لم تجب أي جملة عنه، " +
  "فقل بالضبط: ليس في مستنداتنا.";

// المساعد، مجمّعاً من الكتاب: الاسترجاع (14)، وقاعدة باستشهادات (3 و14)،
// وفحوص على الجواب (14 و15)، وسطر تدقيق بلا بيانات شخصية (15).
export async function assistant(docs, {rule = RULE, k = 2} = {}) {
  const search = await index(docs);
  return async function answer(question, user = "anonymous") {
    const sources = await search(question, k);
    const given = sources.map((s) => `[${s.id}] ${s.text}`).join("\n");
    const prompt = `${given}\n\n${question}`;
    const session = new LlamaChatSession({
      contextSequence: context.getSequence(),
      autoDisposeSequence: true,
      systemPrompt: rule,
    });
    const reply = await session.prompt(prompt, {temperature: 0, maxTokens: 150});
    const text = reply.trim();
    session.dispose();
    const refused = text.includes("ليس في مستنداتنا");
    const {cited, problems} = citations(text, sources);
    problems.push(...secrets(text));
    if (!refused && cited.length === 0) {
      problems.push("no citation");
    }
    const ok = problems.length === 0;
    const result = {text, sources, refused, cited, problems, ok};
    audit(user, question, result);
    return result;
  };
}
