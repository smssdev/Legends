import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";
import {index} from "./embed.mjs";
import {audit, citations, secrets} from "./checks.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});

export const RULE =
  "You are the assistant of a small development team. Answer the " +
  "question in one sentence, only from the documents below, and cite " +
  "the document id in brackets, like [deploy]. If the answer is not " +
  "in the documents, say exactly: Not in our documents.";

// The rule many guides recommend: quote the source, then answer.
export const QUOTE_FIRST =
  "You are the assistant of a small development team. First quote, in " +
  "double quotes, the sentence of the documents that answers the " +
  "question; then answer in one sentence and cite the document id in " +
  "brackets, like [deploy]. If no sentence answers it, say exactly: " +
  "Not in our documents.";

// The assistant, assembled from the book: retrieval (14), a rule with
// citations (3, 14), checks on the answer (14, 15), and an audit line
// without personal data (15).
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
    const refused = text.includes("Not in our documents");
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
