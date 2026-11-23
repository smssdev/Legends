"""Writes and runs the examples of Book 7, chapter "Retrieval: AI That Knows Your Data", in English and Arabic: a
café handbook searched three ways (shared words, the chat model's embeddings, a real embedding model), scored on
questions whose right document is known; then the model answering with and without the retrieved documents,
with citations, and saying when the answer is not there. Then chunking a long document, checking citations,
and measuring retrieval at one, two and three documents.
Run: python3 make.py   (needs Node 22, the book's model and a small embedding model, both downloaded once)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

DOCS_EN = [
    ("loyalty", "Every paid hot drink earns one stamp. The 10th stamp gives a free hot drink up to the price of "
                "a large latte. Stamps never expire."),
    ("branches", "The loyalty card works in both branches, Nasr City and Zamalek."),
    ("refunds", "A refunded drink removes its stamp. Refunds are given within 24 hours, with the receipt."),
    ("hours", "We open from 8:00 to 23:00 every day, and from 9:00 on Fridays."),
    ("prices", "From 1 January a large latte costs 50 pounds, a small latte 40, a tea 25 and an espresso 30."),
    ("wifi", "Wi-Fi is free for customers; the password is printed on the receipt."),
    ("allergens", "Oat and almond milk are available for 10 pounds extra. Our cakes contain gluten and nuts."),
    ("app", "Orders placed in the app are ready in about 10 minutes; pay in the app or at the counter."),
    ("delivery", "We do not deliver; every order is collected at the counter."),
    ("gifts", "Gift cards are sold from 100 to 1000 pounds and are valid for one year."),
]
DOCS_AR = [
    ("loyalty", "كل مشروب ساخن مدفوع يكسب طابعاً. والطابع العاشر يعطي مشروباً ساخناً مجانياً حتى سعر اللاتيه "
                "الكبير. والطوابع لا تنتهي صلاحيتها."),
    ("branches", "بطاقة الولاء تعمل في الفرعين، مدينة نصر والزمالك."),
    ("refunds", "المشروب المسترد يلغي طابعه. ويُسترد المبلغ خلال 24 ساعة، مع الإيصال."),
    ("hours", "نفتح من 8:00 إلى 23:00 كل يوم، ومن 9:00 يوم الجمعة."),
    ("prices", "من 1 يناير يصير سعر اللاتيه الكبير 50 جنيهاً، والصغير 40، والشاي 25، والإسبريسو 30."),
    ("wifi", "الواي فاي مجاني للعملاء؛ وكلمة المرور مطبوعة على الإيصال."),
    ("allergens", "حليب الشوفان واللوز متاحان بـ 10 جنيهات إضافية. وكعكاتنا تحتوي على الغلوتين والمكسرات."),
    ("app", "الطلبات من التطبيق تجهز في نحو 10 دقائق؛ والدفع في التطبيق أو عند الكاونتر."),
    ("delivery", "لا نوصّل الطلبات؛ كل طلب يُستلم من الكاونتر."),
    ("gifts", "بطاقات الهدايا تُباع من 100 إلى 1000 جنيه وصالحة لسنة واحدة."),
]
QUESTIONS_EN = [
    ("What time do you open on Friday?", "hours"),
    ("Is there internet?", "wifi"),
    ("How much is a big latte?", "prices"),
    ("If I return a coffee, do I lose the stamp?", "refunds"),
    ("Can I use my card in Zamalek?", "branches"),
    ("Do you have oat milk?", "allergens"),
    ("Can you bring my order to my office?", "delivery"),
    ("How long does a gift card last?", "gifts"),
]
QUESTIONS_AR = [
    ("متى تفتحون يوم الجمعة؟", "hours"),
    ("هل يوجد إنترنت؟", "wifi"),
    ("كم سعر اللاتيه الكبير؟", "prices"),
    ("إذا أرجعت قهوة، هل أخسر الطابع؟", "refunds"),
    ("هل أستطيع استخدام بطاقتي في الزمالك؟", "branches"),
    ("هل عندكم حليب شوفان؟", "allergens"),
    ("هل توصلون طلبي إلى مكتبي؟", "delivery"),
    ("كم تدوم بطاقة الهدية؟", "gifts"),
]
ASKED_EN = [
    ("Can I use my loyalty card in Zamalek?", "zamalek"),
    ("How much extra is oat milk?", "10"),
    ("How long is a gift card valid?", "year"),
    ("Do you sell sandwiches?", None),
]
ASKED_AR = [
    ("هل أستطيع استخدام بطاقة الولاء في الزمالك؟", "الزمالك"),
    ("كم يكلّف حليب الشوفان إضافةً؟", "10"),
    ("كم مدة صلاحية بطاقة الهدية؟", "سنة"),
    ("هل تبيعون السندويتشات؟", None),
]


def js(value):
    return json.dumps(value, ensure_ascii=False, indent=1)


T = {
    "en": dict(
        w_docs=js(DOCS_EN), w_questions=js(QUESTIONS_EN), w_asked=js(ASKED_EN),
        w_rule="Answer the customer's question only from the documents below, in one sentence, and cite the "
               "document id in brackets, like [hours]. If the answer is not in the documents, say exactly: "
               "Not in our documents.",
        w_plain="Answer the customer's question in one sentence.",
        w_none="Not in our documents",
        w_handbook="# Loyalty\nEvery paid hot drink earns one stamp.\nThe 10th stamp gives a free drink.\n\n"
                   "# Refunds\nA refunded drink removes its stamp.\n\n# Hours\nWe open at 8, and at 9 on Fridays.\n",
        w_c_words="The simplest search: the document that shares the most words with the question.",
        w_c_vectors="Embeddings: each text becomes a list of numbers; similar meanings, nearby lists.",
        w_c_chat="The chat model used for embeddings, and a model made for them.",
        w_c_without="Without the documents, the model answers from what it learned in general.",
        w_c_with="With the two closest documents, a rule, and citations.",
        w_c_chunks="Split a long document at its headings, so each piece is about one thing.",
        w_c_cite="Every citation must name a real document, and the document must contain the answer's numbers.",
        w_c_hits="Is the right document among the first k?",
    ),
    "ar": dict(
        w_docs=js(DOCS_AR), w_questions=js(QUESTIONS_AR), w_asked=js(ASKED_AR),
        w_rule="أجب عن سؤال العميل من المستندات أدناه فقط، في جملة واحدة، واذكر معرّف المستند بين قوسين "
               "معقوفين، مثل [hours]. وإن لم يكن الجواب في المستندات، فقل بالضبط: ليس في مستنداتنا.",
        w_plain="أجب عن سؤال العميل في جملة واحدة.",
        w_none="ليس في مستنداتنا",
        w_handbook="# الولاء\nكل مشروب ساخن مدفوع يكسب طابعاً.\nالطابع العاشر يعطي مشروباً مجانياً.\n\n"
                   "# الاسترداد\nالمشروب المسترد يلغي طابعه.\n\n# المواعيد\nنفتح في 8، وفي 9 يوم الجمعة.\n",
        w_c_words="أبسط بحث: المستند الذي يشارك السؤال أكثر الكلمات.",
        w_c_vectors="التضمينات: كل نص يصير قائمة أرقام؛ والمعاني المتشابهة قوائم متقاربة.",
        w_c_chat="نموذج المحادثة مستخدماً للتضمينات، ونموذج مصنوع لها.",
        w_c_without="بلا المستندات، يجيب النموذج مما تعلّمه عموماً.",
        w_c_with="مع أقرب مستندين، وقاعدة، واستشهادات.",
        w_c_chunks="قسّم المستند الطويل عند عناوينه، ليكون كل جزء عن شيء واحد.",
        w_c_cite="كل استشهاد يجب أن يسمّي مستنداً حقيقياً، والمستند يجب أن يحتوي أرقام الجواب.",
        w_c_hits="هل المستند الصحيح بين أول k؟",
    ),
}

EMBED = """import {getLlama, LlamaLogLevel, resolveModelFile} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

// A small model made for embeddings: Qwen3 Embedding 0.6B (Apache 2.0), 640 MB, downloaded once.
export const EMBEDDER = "hf:Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0";

// {w_c_vectors}
export async function embedder(which = "embedding") {
  const llama = await getLlama({gpu: false, logLevel: LlamaLogLevel.error});
  const model =
    which === "chat" ? await loadModel() : await llama.loadModel({modelPath: await resolveModelFile(EMBEDDER)});
  const context = await model.createEmbeddingContext({contextSize: 512});
  return async (text) => (await context.getEmbeddingFor(text)).vector;
}

export function cosine(a, b) {
  let dot = 0;
  let na = 0;
  let nb = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return dot / Math.sqrt(na * nb);
}

// The k documents closest to a question.
export async function nearest(embed, docs, question, k = 2) {
  const vectors = docs.vectors ?? (docs.vectors = await Promise.all(docs.map(([, text]) => embed(text))));
  const q = await embed(question);
  return vectors
    .map((v, i) => ({id: docs[i][0], text: docs[i][1], score: cosine(q, v)}))
    .sort((a, b) => b.score - a.score)
    .slice(0, k);
}
"""

FILES = {
    "lib/embed.mjs": EMBED,
    "data/docs.mjs": "export const DOCS = {w_docs};\n",
    "data/questions.mjs": "export const QUESTIONS = {w_questions};\nexport const ASKED = {w_asked};\n",
    "data/handbook.md": "{w_handbook}",
    "search.mjs": """import {DOCS} from "./data/docs.mjs";
import {QUESTIONS} from "./data/questions.mjs";
import {embedder, nearest} from "./lib/embed.mjs";

// {w_c_words}
const words = (text) => new Set(text.toLowerCase().match(/[\\p{L}\\d]+/gu));
function byWords(question) {
  const q = words(question);
  const shared = DOCS.map(([id, text]) => [id, [...words(text)].filter((w) => q.has(w)).length]);
  return shared.sort((a, b) => b[1] - a[1])[0][0];
}

// {w_c_chat}
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
""",
    "rag.mjs": """import {LlamaChatSession} from "node-llama-cpp";
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
  // {w_c_without}
  console.log(`  without: ${await ask(`{w_plain}\\n\\n${question}`)}`);
  // {w_c_with}
  const found = await nearest(embed, docs, question, 2);
  const sources = found.map(({id, text}) => `[${id}] ${text}`).join("\\n");
  const answer = await ask(`{w_rule}\\n\\n${sources}\\n\\n${question}`);
  const ok = expected ? answer.toLowerCase().includes(expected) : answer.includes("{w_none}");
  console.log(`  with ${found.map((f) => f.id).join(", ")}: ${answer}  ${ok ? "" : "<- CHECK"}`);
}
""",
    # Projects
    "chunk.mjs": """import fs from "node:fs";

// {w_c_chunks}
export function chunks(markdown) {
  return markdown
    .split(/^(?=# )/m)
    .map((part) => part.trim())
    .filter(Boolean)
    .map((part) => {
      const [title, ...body] = part.split("\\n");
      return {id: title.replace(/^# /, "").toLowerCase(), text: body.join(" ")};
    });
}

for (const {id, text} of chunks(fs.readFileSync("data/handbook.md", "utf8"))) {
  console.log(`[${id}] ${text}`);
}
""",
    "cite.mjs": """import {DOCS} from "./data/docs.mjs";

// {w_c_cite}
export function checkCitations(answer) {
  const problems = [];
  const cited = [...answer.matchAll(/\\[([\\w-]+)\\]/g)].map((m) => m[1]);
  const numbers = answer.match(/\\d+/g) ?? [];
  for (const id of cited) {
    const doc = DOCS.find(([docId]) => docId === id);
    if (!doc) {
      problems.push(`[${id}] is not a document`);
    } else {
      for (const n of numbers.filter((n) => !doc[1].includes(n))) {
        problems.push(`${n} is not in [${id}]`);
      }
    }
  }
  return cited.length === 0 ? ["no citation"] : problems;
}

for (const answer of [
  "Oat milk costs 10 pounds extra [allergens].",
  "Oat milk costs 15 pounds extra [allergens].",
  "Gift cards are valid for one year [gift-cards].",
  "Yes, delivery takes about 30 minutes.",
]) {
  const problems = checkCitations(answer);
  console.log(`${problems.length ? "FAIL" : "ok  "} ${answer}  ${problems.join("; ")}`);
}
""",
    "hits.mjs": """import {DOCS} from "./data/docs.mjs";
import {QUESTIONS} from "./data/questions.mjs";
import {embedder, nearest} from "./lib/embed.mjs";

// {w_c_hits}
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
""",
}

RUNS = [
    ("search.sh", "node search.mjs"),
    ("rag.sh", "node rag.mjs"),
    ("projects/chunk.sh", "node chunk.mjs"),
    ("projects/cite.sh", "node cite.mjs"),
    ("projects/hits.sh", "node hits.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
