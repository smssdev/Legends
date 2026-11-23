"""Writes and runs the examples of Book 7, chapter "Automating Repetitive Work", in English and Arabic: customer
reviews labelled by the model and by plain keyword rules, both scored against labels a person wrote and timed;
order notes turned into data by the model and by a regular expression; and a cleaning script written once by
the model and then run on every row with no model at all. Then a cache so nothing is asked twice, a queue for
the items where model and rules disagree, and the generated script tested before it is trusted.
Run: python3 make.py   (needs Node 22 and the book's model; B7_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

REVIEWS_EN = [
    ("The latte was perfect, rich and smooth.", "taste", "pos"),
    ("Too expensive for such a small cup.", "price", "neg"),
    ("The app crashed twice while I was paying.", "app", "neg"),
    ("The barista was so kind and quick.", "service", "pos"),
    ("Cold coffee and a long wait.", "service", "neg"),
    ("Great value, the large size is worth it.", "price", "pos"),
    ("Ordering in the app takes ten seconds, love it.", "app", "pos"),
    ("The cake was dry and tasteless.", "taste", "neg"),
    ("Nobody greeted us and the table was dirty.", "service", "neg"),
    ("I can't believe a tea costs 40 pounds now.", "price", "neg"),
    ("Not bad, but the espresso was bitter.", "taste", "neg"),
    ("The loyalty stamps did not show up after my order.", "app", "neg"),
]
REVIEWS_AR = [
    ("اللاتيه كان رائعاً، غنياً وناعماً.", "taste", "pos"),
    ("غالٍ جداً لكوب بهذا الصغر.", "price", "neg"),
    ("التطبيق توقف مرتين وأنا أدفع.", "app", "neg"),
    ("الباريستا كان لطيفاً وسريعاً جداً.", "service", "pos"),
    ("قهوة باردة وانتظار طويل.", "service", "neg"),
    ("قيمة ممتازة، الحجم الكبير يستحق.", "price", "pos"),
    ("الطلب من التطبيق يأخذ عشر ثوانٍ، أحببته.", "app", "pos"),
    ("الكيك كان جافاً بلا طعم.", "taste", "neg"),
    ("لم يرحب بنا أحد والطاولة متسخة.", "service", "neg"),
    ("لا أصدق أن الشاي صار بـ 40 جنيهاً.", "price", "neg"),
    ("ليس سيئاً، لكن الإسبريسو كان مُرّاً.", "taste", "neg"),
    ("طوابع الولاء لم تظهر بعد طلبي.", "app", "neg"),
]

NOTES_EN = [
    ("2 large lattes", ["latte", "large", 2]),
    ("one small tea please", ["tea", "small", 1]),
    ("latte x3, large", ["latte", "large", 3]),
    ("a large espresso and nothing else", ["espresso", "large", 1]),
    ("3 teas (small)", ["tea", "small", 3]),
    ("espresso", ["espresso", "unknown", 1]),
    ("two small lattes for the office", ["latte", "small", 2]),
    ("LARGE TEA", ["tea", "large", 1]),
]
NOTES_AR = [
    ("2 لاتيه كبير", ["latte", "large", 2]),
    ("شاي صغير واحد من فضلك", ["tea", "small", 1]),
    ("لاتيه ×3، كبير", ["latte", "large", 3]),
    ("إسبريسو كبير ولا شيء آخر", ["espresso", "large", 1]),
    ("3 شاي (صغير)", ["tea", "small", 3]),
    ("إسبريسو", ["espresso", "unknown", 1]),
    ("اثنان لاتيه صغير للمكتب", ["latte", "small", 2]),
    ("شاي كبير", ["tea", "large", 1]),
]


def js(rows):
    """Python rows as a JavaScript array literal, one row per line."""
    return "[\n" + "".join(f"  {json.dumps(list(row), ensure_ascii=False)},\n" for row in rows) + "]"


T = {
    "en": dict(
        w_reviews=js(REVIEWS_EN),
        w_notes=js(NOTES_EN),
        w_label="Label this café review with its topic (price, taste, service or app) and its sentiment "
                "(pos or neg).",
        w_extract="Read this coffee order note. Reply with the drink (latte, tea or espresso), the size (small, "
                  "large or unknown) and the count.",
        w_rules_topic='price: ["expensive", "price", "cost", "value", "pounds", "cheap"],\n'
                      '  app: ["app", "ordering", "stamps", "crash", "paying"],\n'
                      '  service: ["barista", "wait", "greeted", "kind", "table", "staff"],\n'
                      '  taste: ["latte", "cake", "espresso", "coffee", "bitter", "dry", "tasteless"],',
        w_rules_neg='["too", "crashed", "cold", "long", "dry", "tasteless", "nobody", "dirty", "not", '
                    '"bitter", "can\'t"]',
        w_regex_drink="latte|tea|espresso",
        w_regex_size="small|large",
        w_words='{one: 1, two: 2, three: 3}',
        w_names='{latte: "latte", tea: "tea", espresso: "espresso", small: "small", large: "large"}',
        w_dates="12/01/2026\n2026-1-3\n3 Jan 2026\n01.02.2026\nJanuary 15, 2026\n2026/02/28",
        w_codegen="Write a JavaScript function toIso(text) that converts dates in these formats to YYYY-MM-DD. "
                  "Day comes before month when both are numbers. Return only the function, in one code block.",
        w_c_truth="Labels written by a person: the answer key for both methods.",
        w_c_rules="The plain way: keyword rules, written in five minutes.",
        w_c_model="The model way: one request per review, with a schema.",
        w_c_regex="A regular expression for the same notes.",
        w_c_once="Ask the model for the code once, then run the code on every row: no model per row.",
        w_c_cache="The same item is never asked twice: answers are kept in a file, by the hash of the request.",
        w_c_queue="Where model and rules disagree, a person decides.",
        w_c_tested="The generated function is tested on rows with known answers before it touches the rest.",
    ),
    "ar": dict(
        w_reviews=js(REVIEWS_AR),
        w_notes=js(NOTES_AR),
        w_label="صنّف هذا التقييم لمقهى بموضوعه (price أو taste أو service أو app) وشعوره (pos أو neg).",
        w_extract="اقرأ ملاحظة طلب القهوة هذه. أجب بالمشروب (latte أو tea أو espresso)، والحجم (small أو large "
                  "أو unknown)، والعدد.",
        w_rules_topic='price: ["غال", "سعر", "جنيه", "قيمة", "رخيص"],\n'
                      '  app: ["التطبيق", "طوابع", "توقف", "أدفع"],\n'
                      '  service: ["الباريستا", "انتظار", "يرحب", "لطيف", "الطاولة"],\n'
                      '  taste: ["اللاتيه", "الكيك", "الإسبريسو", "قهوة", "مر", "جاف", "طعم"],',
        w_rules_neg='["جداً لكوب", "توقف", "باردة", "طويل", "جاف", "بلا طعم", "لم ", "متسخة", "مُرّ", "لا أصدق"]',
        w_regex_drink="لاتيه|شاي|إسبريسو",
        w_regex_size="صغير|كبير",
        w_words='{"واحد": 1, "اثنان": 2, "ثلاثة": 3}',
        w_names='{"لاتيه": "latte", "شاي": "tea", "إسبريسو": "espresso", "صغير": "small", "كبير": "large"}',
        w_dates="12/01/2026\n2026-1-3\n3 يناير 2026\n01.02.2026\n15 يناير 2026\n2026/02/28",
        w_codegen="اكتب دالة JavaScript باسم toIso(text) تحوّل التواريخ بهذه الصيغ إلى YYYY-MM-DD. "
                  "اليوم قبل الشهر حين يكون الاثنان رقمين. أعِد الدالة فقط، في كتلة كود واحدة.",
        w_c_truth="تصنيفات كتبها إنسان: مفتاح الإجابة للطريقتين.",
        w_c_rules="الطريقة العادية: قواعد كلمات مفتاحية، كُتبت في خمس دقائق.",
        w_c_model="طريقة النموذج: طلب لكل تقييم، بمخطط.",
        w_c_regex="تعبير نمطي للملاحظات نفسها.",
        w_c_once="اطلب الكود من النموذج مرة، ثم شغّل الكود على كل صف: بلا نموذج لكل صف.",
        w_c_cache="العنصر نفسه لا يُسأل مرتين: تُحفظ الأجوبة في ملف، ببصمة الطلب.",
        w_c_queue="حيث يختلف النموذج والقواعد، يقرر إنسان.",
        w_c_tested="تُختبر الدالة المولّدة على صفوف أجوبتها معروفة قبل أن تلمس الباقي.",
    ),
}

ASK = """import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});

// One question in a fresh conversation, at temperature 0.
export async function ask(prompt, options = {}) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
  });
  const answer = await session.prompt(prompt, {
    temperature: 0,
    maxTokens: options.maxTokens ?? 200,
    grammar: options.grammar,
  });
  session.dispose();
  return answer.trim();
}

export {model};
"""

CACHE = """import crypto from "node:crypto";
import fs from "node:fs";
import {ask} from "./ask.mjs";

// {w_c_cache}
const FILE = "cache.json";
const saved = fs.existsSync(FILE) ? JSON.parse(fs.readFileSync(FILE, "utf8")) : {};
export const stats = {asked: 0, cached: 0};

export async function cachedAsk(prompt, options = {}) {
  const key = crypto.createHash("sha256").update(prompt).digest("hex").slice(0, 16);
  if (key in saved) {
    stats.cached++;
    return saved[key];
  }
  stats.asked++;
  saved[key] = await ask(prompt, options);
  fs.writeFileSync(FILE, JSON.stringify(saved, null, 1));
  return saved[key];
}
"""

FILES = {
    "lib/ask.mjs": ASK,
    "lib/cache.mjs": CACHE,
    "data/reviews.mjs": """// {w_c_truth}
export const REVIEWS = {w_reviews};
""",
    "data/notes.mjs": "export const NOTES = {w_notes};\n",
    "data/dates.txt": "{w_dates}\n",
    "label.mjs": """import {ask, model} from "./lib/ask.mjs";
import {REVIEWS} from "./data/reviews.mjs";

// {w_c_rules}
const TOPICS = {
  {w_rules_topic}
};
const NEGATIVE = {w_rules_neg};
function rules(text) {
  const lower = text.toLowerCase();
  const topic = Object.keys(TOPICS).find((t) => TOPICS[t].some((w) => lower.includes(w))) ?? "taste";
  const sentiment = NEGATIVE.some((w) => lower.includes(w)) ? "neg" : "pos";
  return {topic, sentiment};
}

// {w_c_model}
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    topic: {enum: ["price", "taste", "service", "app"]},
    sentiment: {enum: ["pos", "neg"]},
  },
});
async function byModel(text) {
  return JSON.parse(await ask(`{w_label}\\n\\n${text}`, {grammar}));
}

for (const [name, method] of [["rules", rules], ["model", byModel]]) {
  const start = performance.now();
  let right = 0;
  for (const [text, topic, sentiment] of REVIEWS) {
    const got = await method(text);
    right += got.topic === topic && got.sentiment === sentiment ? 1 : 0;
  }
  const ms = performance.now() - start;
  console.log(`${name.padEnd(5)} ${right} of ${REVIEWS.length} right, ${ms < 1000 ? "under a second" : `${Math.round(ms / 1000)} s`}`);
}
""",
    "extract.mjs": """import {ask, model} from "./lib/ask.mjs";
import {NOTES} from "./data/notes.mjs";

// {w_c_regex}
const WORDS = {w_words};
const NAMES = {w_names};
function byRegex(note) {
  const lower = note.toLowerCase();
  const drink = NAMES[lower.match(/{w_regex_drink}/)?.[0]];
  const size = NAMES[lower.match(/{w_regex_size}/)?.[0]] ?? "unknown";
  const digits = lower.match(/\\d+/)?.[0];
  const word = Object.keys(WORDS).find((w) => lower.includes(w));
  return [drink, size, Number(digits ?? WORDS[word] ?? 1)];
}

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    drink: {enum: ["latte", "tea", "espresso"]},
    size: {enum: ["small", "large", "unknown"]},
    count: {type: "integer"},
  },
});
async function byModel(note) {
  const {drink, size, count} = JSON.parse(await ask(`{w_extract}\\n\\n${note}`, {grammar}));
  return [drink, size, count];
}

const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
for (const [note, truth] of NOTES) {
  const [regex, modelAnswer] = [byRegex(note), await byModel(note)];
  console.log(`${same(regex, truth) ? "ok " : "BAD"} ${same(modelAnswer, truth) ? "ok " : "BAD"}  ${note}`);
}
console.log("(first column: the regular expression; second: the model)");
""",
    "once.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

// {w_c_once}
const rows = fs.readFileSync("data/dates.txt", "utf8").trim().split("\\n");
const answer = await ask(`{w_codegen}\\n\\n${rows.join("\\n")}`, {maxTokens: 1500});
// The code block, even when the answer stopped before closing it.
const code = answer.match(/```(?:\\w+)?\\n([\\s\\S]*?)(?:```|$)/)?.[1] ?? answer;
fs.writeFileSync("toIso.mjs", `${code}\\nexport {toIso};\\n`);
let toIso;
try {
  ({toIso} = await import("./toIso.mjs"));
} catch (error) {
  console.log(`toIso.mjs does not load: ${error.message}`);
  process.exit(0);
}
for (const row of rows) {
  let result;
  try {
    result = toIso(row);
  } catch (error) {
    result = `${error.name}: ${error.message}`;
  }
  console.log(`${row.padEnd(18)} -> ${result}`);
}
""",
    # Projects
    "cached.mjs": """import {REVIEWS} from "./data/reviews.mjs";
import {cachedAsk, stats} from "./lib/cache.mjs";

for (const [text] of REVIEWS.slice(0, 4)) {
  await cachedAsk(`{w_label}\\n\\n${text}`);
}
console.log(`asked the model ${stats.asked} times, answered from the cache ${stats.cached} times`);
""",
    "queue.mjs": """import {ask, model} from "./lib/ask.mjs";
import {REVIEWS} from "./data/reviews.mjs";

const TOPICS = {
  {w_rules_topic}
};
const rule = (text) => Object.keys(TOPICS).find((t) => TOPICS[t].some((w) => text.toLowerCase().includes(w)));
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {topic: {enum: ["price", "taste", "service", "app"]}},
});

// {w_c_queue}
let agreed = 0;
const queue = [];
for (const [text, truth] of REVIEWS) {
  const {topic} = JSON.parse(await ask(`{w_label}\\n\\n${text}`, {grammar}));
  if (topic === rule(text)) {
    agreed++;
    if (topic !== truth) {
      console.log(`agreed and WRONG: ${text}`);
    }
  } else {
    queue.push(`${text}  (model: ${topic}, rules: ${rule(text) ?? "none"}, truth: ${truth})`);
  }
}
console.log(`${agreed} decided automatically, ${queue.length} for a person:`);
queue.forEach((item) => console.log(`  ${item}`));
""",
    "tested.mjs": """let toIso;
try {
  ({toIso} = await import("./toIso.mjs"));
} catch (error) {
  console.log(`not safe: toIso.mjs does not load (${error.message})`);
  process.exit(0);
}

// {w_c_tested}
const known = [
  ["12/01/2026", "2026-01-12"],
  ["2026-1-3", "2026-01-03"],
  ["01.02.2026", "2026-02-01"],
  ["2026/02/28", "2026-02-28"],
];
let right = 0;
for (const [input, expected] of known) {
  let got;
  try {
    got = toIso(input);
  } catch (error) {
    got = error.name;
  }
  right += got === expected ? 1 : 0;
  console.log(`${got === expected ? "pass" : "FAIL"} ${input} -> ${got} (expected ${expected})`);
}
console.log(right === known.length ? "safe to run on the rest" : "not safe: fix the function first");
""",
}

RUNS = [
    ("label.sh", "node label.mjs"),
    ("extract.sh", "node extract.mjs"),
    ("once.sh", "node once.mjs"),
    ("projects/cached.sh", "node cached.mjs && node cached.mjs"),
    ("projects/queue.sh", "node queue.mjs"),
    ("projects/tested.sh", "node tested.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS, made=["toIso.mjs"])


if __name__ == "__main__":
    main()
