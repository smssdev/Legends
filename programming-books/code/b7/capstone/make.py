"""Writes and runs the examples of Book 7, chapter "Capstone: An AI-Powered Assistant for Your Team", in English and
Arabic: an assistant that answers a development team's questions from the team's own documents, built from the
parts of the book (a provider, retrieval, a rule with citations, checks on every answer, an audit log without
personal data) and measured with an evaluation set. Then a command-line assistant, a new document that turns a
refusal into an answer, and two prompts compared on the same evaluation.
Run: python3 make.py   (needs Node 22 and the book's two models; B7_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

DOCS_EN = [
    ["conventions", "We use ES modules and named exports. Tests live next to the code in .test.mjs files and run "
                    "with node --test."],
    ["reviews", "Every pull request needs one approval and passing tests. Never merge your own pull request."],
    ["deploy", "We deploy from the main branch on Tuesdays and Thursdays at 11:00, with npm run deploy. We never "
               "deploy on Fridays."],
    ["oncall", "This week the on-call developer is Omar. Call him only for production incidents."],
    ["secrets", "API keys live in the team vault. Never put a key in the code, in a commit or in a chat."],
    ["commits", "Commit messages follow Conventional Commits: type(scope): subject, at most 72 characters."],
]
DOCS_AR = [
    ["conventions", "نستخدم وحدات ES والتصدير المسمّى. والاختبارات بجانب الكود في ملفات ‎.test.mjs وتُشغَّل بـ "
                    "node --test."],
    ["reviews", "كل طلب دمج يحتاج موافقة واحدة واختبارات ناجحة. ولا تدمج طلب الدمج الخاص بك أبداً."],
    ["deploy", "ننشر من الفرع main يومي الثلاثاء والخميس في الساعة 11:00، بـ npm run deploy. ولا ننشر يوم الجمعة "
               "أبداً."],
    ["oncall", "المطور المناوب هذا الأسبوع عمر. اتصل به لأعطال بيئة الإنتاج فقط."],
    ["secrets", "مفاتيح الـ API في خزنة الفريق. ولا تضع مفتاحاً في الكود ولا في حفظ ولا في محادثة أبداً."],
    ["commits", "رسائل الحفظ تتبع Conventional Commits: type(scope): وموضوع، 72 حرفاً على الأكثر."],
]
EVAL_EN = [
    ["How do I run the tests?", "conventions", "node --test"],
    ["Can I deploy on a Friday?", "deploy", "no"],
    ["On which days do we deploy?", "deploy", "tuesday"],
    ["May I merge my own pull request?", "reviews", "no"],
    ["Who is on call this week?", "oncall", "omar"],
    ["Where should I keep an API key?", "secrets", "vault"],
    ["What format do commit messages use?", "commits", "conventional"],
    ["How many vacation days do we get?", None, None],
]
EVAL_AR = [
    ["كيف أشغّل الاختبارات؟", "conventions", "node --test"],
    ["هل أستطيع النشر يوم الجمعة؟", "deploy", "لا"],
    ["في أي الأيام ننشر؟", "deploy", "الثلاثاء"],
    ["هل يجوز أن أدمج طلب الدمج الخاص بي؟", "reviews", "لا"],
    ["من المناوب هذا الأسبوع؟", "oncall", "عمر"],
    ["أين أحفظ مفتاح API؟", "secrets", "الخزنة"],
    ["ما صيغة رسائل الحفظ؟", "commits", "conventional"],
    ["كم يوم إجازة لدينا؟", None, None],
]

T = {
    "en": dict(
        w_docs=json.dumps(DOCS_EN, ensure_ascii=False, indent=1),
        w_eval=json.dumps(EVAL_EN, ensure_ascii=False, indent=1),
        w_rule="You are the assistant of a small development team. Answer the question in one sentence, only from "
               "the documents below, and cite the document id in brackets, like [deploy]. If the answer is not in "
               "the documents, say exactly: Not in our documents.",
        w_quote="You are the assistant of a small development team. First quote, in double quotes, the sentence of "
                "the documents that answers the question; then answer in one sentence and cite the document id in "
                "brackets, like [deploy]. If no sentence answers it, say exactly: Not in our documents.",
        w_none="Not in our documents",
        w_vacation='["vacation", "Every developer gets 21 days of paid vacation a year, booked in the team calendar."]',
        w_demo='"How do I run the tests?", "Can I deploy on a Friday?", "How many vacation days do we get?"',
        w_q_vacation="How many vacation days do we get?",
        w_c_parts="The assistant, assembled from the book: retrieval (14), a rule with citations (3, 14), checks on "
                  "the answer (14, 15), and an audit line without personal data (15).",
        w_c_eval="The evaluation: does search find the right document, is the answer right and cited, and is the "
                 "refusal said exactly when it should be?",
        w_c_cli="The assistant from the command line.",
        w_c_grow="A new document turns a refusal into an answer.",
        w_c_ab="Two prompts, the same evaluation: decide by the numbers.",
        w_c_more="Other words a right answer may use, by document.",
        w_c_quote="The rule many guides recommend: quote the source, then answer.",
        w_more='{"reviews": ["never"], "commits": ["type(scope)"]}',
        w_c_fair="Every answer marked WRONG was read by a person: each was right. The words a right answer may "
                 "use, widened, and the two prompts measured again.",
    ),
    "ar": dict(
        w_docs=json.dumps(DOCS_AR, ensure_ascii=False, indent=1),
        w_eval=json.dumps(EVAL_AR, ensure_ascii=False, indent=1),
        w_rule="أنت مساعد فريق تطوير صغير. أجب عن السؤال في جملة واحدة، من المستندات أدناه فقط، واذكر معرّف المستند "
               "بين قوسين معقوفين، مثل [deploy]. وإن لم يكن الجواب في المستندات، فقل بالضبط: ليس في مستنداتنا.",
        w_quote="أنت مساعد فريق تطوير صغير. اقتبس أولاً، بين علامتي تنصيص، جملة المستندات التي تجيب عن السؤال؛ ثم "
                "أجب في جملة واحدة واذكر معرّف المستند بين قوسين معقوفين، مثل [deploy]. وإن لم تجب أي جملة عنه، فقل "
                "بالضبط: ليس في مستنداتنا.",
        w_none="ليس في مستنداتنا",
        w_vacation='["vacation", "لكل مطور 21 يوم إجازة مدفوعة في السنة، تُحجز في تقويم الفريق."]',
        w_demo='"كيف أشغّل الاختبارات؟", "هل أستطيع النشر يوم الجمعة؟", "كم يوم إجازة لدينا؟"',
        w_q_vacation="كم يوم إجازة لدينا؟",
        w_c_parts="المساعد، مجمّعاً من الكتاب: الاسترجاع (14)، وقاعدة باستشهادات (3 و14)، وفحوص على الجواب (14 و15)، "
                  "وسطر تدقيق بلا بيانات شخصية (15).",
        w_c_eval="التقييم: هل يجد البحث المستند الصحيح، وهل الجواب صحيح ومستشهد، وهل يُقال الرفض بالضبط حين يجب؟",
        w_c_cli="المساعد من سطر الأوامر.",
        w_c_grow="مستند جديد يحوّل رفضاً إلى جواب.",
        w_c_ab="أمران، والتقييم نفسه: قرر بالأرقام.",
        w_c_more="كلمات أخرى قد يستخدمها الجواب الصحيح، لكل مستند.",
        w_c_quote="القاعدة التي توصي بها أدلة كثيرة: اقتبس المصدر، ثم أجب.",
        w_more='{"reviews": ["أبداً"], "secrets": ["خزنة"], "commits": ["type(scope)"]}',
        w_c_fair="قرأ إنسان كل جواب عُلّم WRONG: كان كل واحد صحيحاً. فوُسّعت الكلمات التي قد يستخدمها الجواب "
                 "الصحيح، وقيس الأمران من جديد.",
    ),
}


def js_string(text, indent="  ", width=66):
    """A long sentence as a JS string concatenation, so no listing line wraps."""
    lines, line = [], ""
    for word in text.split(" "):
        if line and len(line) + len(word) + 1 > width:
            lines.append(line + " ")
            line = word
        else:
            line = f"{line} {word}" if line else word
    lines.append(line)
    return (" +\n" + indent).join(json.dumps(x, ensure_ascii=False) for x in lines)


for _w in T.values():
    _w["w_rule_js"] = js_string(_w["w_rule"])
    _w["w_quote_js"] = js_string(_w["w_quote"])

EMBED = """import {getLlama, LlamaLogLevel, resolveModelFile} from "node-llama-cpp";

const EMBEDDER = "hf:Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0";

export async function embedder() {
  const llama = await getLlama({gpu: false, logLevel: LlamaLogLevel.error});
  const model = await llama.loadModel({modelPath: await resolveModelFile(EMBEDDER)});
  const context = await model.createEmbeddingContext({contextSize: 512});
  return async (text) => (await context.getEmbeddingFor(text)).vector;
}

function cosine(a, b) {
  let [dot, na, nb] = [0, 0, 0];
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return dot / Math.sqrt(na * nb);
}

// An index over documents: embedded once, searched by meaning.
export async function index(docs) {
  const embed = await embedder();
  const vectors = await Promise.all(docs.map(([, text]) => embed(text)));
  return async (question, k = 2) => {
    const q = await embed(question);
    return vectors
      .map((v, i) => ({id: docs[i][0], text: docs[i][1], score: cosine(q, v)}))
      .sort((a, b) => b.score - a.score)
      .slice(0, k);
  };
}
"""

CHECKS = """import crypto from "node:crypto";
import fs from "node:fs";

// Every citation names a document that was given, and its numbers are in that document (Chapter 14).
export function citations(answer, sources) {
  const cited = [...answer.matchAll(/\\[([\\w-]+)\\]/g)].map((m) => m[1]);
  const problems = cited
    .filter((id) => !sources.some((s) => s.id === id))
    .map((id) => `[${id}] was not given`);
  for (const id of cited) {
    const source = sources.find((s) => s.id === id);
    const numbers = answer.match(/\\d+/g) ?? [];
    for (const n of numbers.filter((n) => source && !source.text.includes(n))) {
      problems.push(`${n} is not in [${id}]`);
    }
  }
  return {cited, problems};
}

// No secret leaves, whatever the documents or the model say (Chapter 15).
export function secrets(answer) {
  return /\\b(sk|pk)-[A-Za-z0-9-]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----/.test(answer) ? ["a secret"] : [];
}

// One line per question: the user hashed, emails and phones masked, the outcome (Chapter 15).
export function audit(user, question, result) {
  const masked = question.replace(/[\\w.+-]+@[\\w-]+\\.[\\w.]+/g, "[EMAIL]").replace(/\\b01\\d(?:[ -]?\\d){8}\\b/g, "[PHONE]");
  const entry = {
    user: crypto.createHash("sha256").update(`team:${user}`).digest("hex").slice(0, 10),
    question: masked,
    sources: result.sources.map((s) => s.id),
    ok: result.ok,
  };
  fs.appendFileSync("audit.log", `${JSON.stringify(entry)}\\n`);
}
"""

ASSISTANT = """import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";
import {index} from "./embed.mjs";
import {audit, citations, secrets} from "./checks.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});

export const RULE =
  {w_rule_js};

// {w_c_quote}
export const QUOTE_FIRST =
  {w_quote_js};

// {w_c_parts}
export async function assistant(docs, {rule = RULE, k = 2} = {}) {
  const search = await index(docs);
  return async function answer(question, user = "anonymous") {
    const sources = await search(question, k);
    const given = sources.map((s) => `[${s.id}] ${s.text}`).join("\\n");
    const prompt = `${given}\\n\\n${question}`;
    const session = new LlamaChatSession({
      contextSequence: context.getSequence(),
      autoDisposeSequence: true,
      systemPrompt: rule,
    });
    const reply = await session.prompt(prompt, {temperature: 0, maxTokens: 150});
    const text = reply.trim();
    session.dispose();
    const refused = text.includes("{w_none}");
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
"""

EVAL = """import {DOCS, EVAL} from "./data.mjs";
import {assistant} from "./lib/assistant.mjs";

// {w_c_eval}
export async function evaluate(answer, cases = EVAL) {
  const score = {found: 0, right: 0, refusals: 0, problems: 0};
  const lines = [];
  for (const [question, doc, expected] of cases) {
    const result = await answer(question);
    const found = doc === null || result.sources.some((s) => s.id === doc);
    const words = [expected].flat();
    const right = expected === null ? result.refused : words.some((w) => result.text.toLowerCase().includes(w));
    score.found += found ? 1 : 0;
    score.right += right ? 1 : 0;
    score.refusals += expected === null && result.refused ? 1 : 0;
    score.problems += result.problems.length ? 1 : 0;
    lines.push(`${right ? "right" : "WRONG"} ${found ? "found" : "MISSED"} ${result.problems.join("; ").padEnd(14)} ${question}`);
  }
  return {score, lines};
}

if (process.argv[1].endsWith("eval.mjs")) {
  const {score, lines} = await evaluate(await assistant(DOCS));
  console.log(lines.join("\\n"));
  console.log(`--- found ${score.found}/${EVAL.length}, right ${score.right}/${EVAL.length}, ` +
    `answers with a problem ${score.problems}`);
}
"""

FILES = {
    "lib/embed.mjs": EMBED,
    "lib/checks.mjs": CHECKS,
    "lib/assistant.mjs": ASSISTANT,
    "data.mjs": "export const DOCS = {w_docs};\n\nexport const EVAL = {w_eval};\n\n"
                "// {w_c_more}\nexport const MORE_WORDS = {w_more};\n",
    "eval.mjs": EVAL,
    "demo.mjs": """import {DOCS} from "./data.mjs";
import {assistant} from "./lib/assistant.mjs";

const answer = await assistant(DOCS);
for (const question of [{w_demo}]) {
  const {text, sources, ok, problems} = await answer(question, "mona@example.com");
  console.log(`> ${question}\\n  ${text}\\n  sources: ${sources.map((s) => s.id).join(", ")}; checks: ${ok ? "ok" : problems.join("; ")}`);
}
""",
    "fair.mjs": """import {DOCS, EVAL, MORE_WORDS} from "./data.mjs";
import {assistant, QUOTE_FIRST, RULE} from "./lib/assistant.mjs";
import {evaluate} from "./eval.mjs";

// {w_c_fair}
const fair = EVAL.map(([q, doc, word]) => [q, doc, word === null ? null : [word, ...(MORE_WORDS[doc] ?? [])]]);
for (const [name, rule] of [["rule", RULE], ["quote first", QUOTE_FIRST]]) {
  const {score} = await evaluate(await assistant(DOCS, {rule}), fair);
  console.log(`${name.padEnd(12)} right ${score.right}/8, found ${score.found}/8, problems ${score.problems}`);
}
""",
    # Projects
    "ask.mjs": """import {DOCS} from "./data.mjs";
import {assistant} from "./lib/assistant.mjs";

// {w_c_cli}
const question = process.argv.slice(2).join(" ");
const {text, cited, ok, problems} = await (await assistant(DOCS))(question, process.env.USER);
console.log(text);
console.log(ok ? `(sources: ${cited.join(", ") || "none"})` : `(not checked: ${problems.join("; ")})`);
""",
    "grow.mjs": """import {DOCS} from "./data.mjs";
import {assistant} from "./lib/assistant.mjs";

// {w_c_grow}
const question = "{w_q_vacation}";
for (const docs of [DOCS, [...DOCS, {w_vacation}]]) {
  const {text, cited} = await (await assistant(docs))(question);
  console.log(`${docs.length} documents: ${text}  (${cited.join(", ") || "no citation"})`);
}
""",
    "ab.mjs": """import {DOCS} from "./data.mjs";
import {assistant, QUOTE_FIRST, RULE} from "./lib/assistant.mjs";
import {evaluate} from "./eval.mjs";

// {w_c_ab}
for (const [name, rule] of [["rule", RULE], ["quote first", QUOTE_FIRST]]) {
  const {score, lines} = await evaluate(await assistant(DOCS, {rule}));
  console.log(`${name.padEnd(12)} right ${score.right}/8, found ${score.found}/8, problems ${score.problems}`);
  lines.filter((line) => !line.startsWith("right found")).forEach((line) => console.log(`  ${line}`));
}
""",
}

RUNS = [
    ("demo.sh", "node demo.mjs && tail -n 3 audit.log"),
    ("eval.sh", "node eval.mjs"),
    ("projects/ask.sh", "node ask.mjs \"{w_q_vacation}\""),
    ("projects/grow.sh", "node grow.mjs"),
    ("projects/ab.sh", "node ab.mjs"),
    ("fair.sh", "node fair.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
