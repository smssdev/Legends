"""Writes and runs the examples of Book 7, chapter "How Large Language Models Work", in English and Arabic:
tokens, the next-token probabilities a model computes, temperature, a model inventing an answer, and the facts
of the model file itself; then a token counter, a generator that shows each choice, and a tiny bigram model
in plain JavaScript.
Run: python3 make.py   (needs Node 22; downloads the book’s model, 2.5 GB, the first time)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

T = {
    "en": dict(
        w_prompt="The café sells coffee and",
        w_ask1="Summarize the 2019 paper “Brewing Tokens” by Layla Hassan ",
        w_ask2="in two sentences.",
        w_doubt="If you are not sure the paper exists, say so.",
        w_name="A short, friendly name for a new café:",
        w_corpus='  "the café opens at eight .",\n  "the café sells coffee and tea .",\n  "the café sells cake .",\n'
                 '  "customers drink coffee in the morning .",\n  "customers drink tea at night .",\n'
                 '  "the barista makes coffee .",\n  "the barista makes tea and cake .",',
        w_start="the",
        w_c_tokens="The same sentence in two languages, and how the model cuts each into tokens.",
        w_c_next="Everything a model does is this: given the tokens so far, a probability for every possible next token.",
        w_c_temp="Temperature 0 always takes the most likely token; higher temperatures sample, so the answer changes with the seed.",
        w_c_file="What the model file says about itself.",
        w_c_count="Tokens are what you pay for and what fills the context: count them before you send.",
        w_c_price="An example price per million input tokens, to compare; real prices differ by provider and model.",
        w_c_loop="Generation is a loop: predict, choose, append, repeat. Here each choice is shown with its probability.",
        w_c_bigram="No neural network: count which word follows which, then pick the next word from those counts.",
    ),
    "ar": dict(
        w_prompt="المقهى يبيع القهوة و",
        w_ask1="لخّص في جملتين بحث «تخمير الرموز» ",
        w_ask2="الذي نشرته ليلى حسن عام 2019.",
        w_doubt="وإن لم تكن متأكداً من وجود البحث، فقل ذلك.",
        w_name="اسم قصير ولطيف لمقهى جديد:",
        w_corpus='  "يفتح المقهى في الثامنة .",\n  "يبيع المقهى القهوة والشاي .",\n  "يبيع المقهى الكيك .",\n'
                 '  "يشرب الزبائن القهوة في الصباح .",\n  "يشرب الزبائن الشاي في المساء .",\n'
                 '  "يصنع الباريستا القهوة .",\n  "يصنع الباريستا الشاي والكيك .",',
        w_start="المقهى",
        w_c_tokens="الجملة نفسها بلغتين، وكيف يقطّع النموذج كلاً منهما إلى رموز.",
        w_c_next="كل ما يفعله النموذج هو هذا: بعد الرموز حتى الآن، احتمال لكل رمز ممكن بعدها.",
        w_c_temp="درجة الحرارة 0 تأخذ دائماً الرمز الأرجح؛ والدرجات الأعلى تسحب عشوائياً، فيتغير الجواب مع البذرة.",
        w_c_file="ما يقوله ملف النموذج عن نفسه.",
        w_c_count="الرموز هي ما تدفع ثمنه وما يملأ السياق: عُدّها قبل أن ترسل.",
        w_c_price="سعر مثالي لكل مليون رمز مُدخل، للمقارنة؛ والأسعار الحقيقية تختلف بين المزوّدين والنماذج.",
        w_c_loop="التوليد حلقة: تنبّأ، واختر، وأضف، وكرر. وهنا يُعرض كل اختيار مع احتماله.",
        w_c_bigram="بلا شبكة عصبية: عُدّ أي كلمة تتبع أي كلمة، ثم اختر الكلمة التالية من تلك الأعداد.",
    ),
}

FILES = {
    "tokens.mjs": """import {loadModel} from "./lib/model.mjs";

const model = await loadModel();

// {w_c_tokens}
const sentences = [
  "The café opens at 8:30 and closes at 22:00.",
  "يفتح المقهى في 8:30 ويغلق في 22:00.",
];
for (const sentence of sentences) {
  const tokens = model.tokenize(sentence);
  const pieces = tokens.map((token) => model.detokenize([token]));
  const words = sentence.split(" ").length;
  const size = `${sentence.length} characters, ${tokens.length} tokens`;
  console.log(`${words} words, ${size}`);
  console.log("  " + pieces.map((piece) => `[${piece}]`).join(""));
}
""",
    "next.mjs": """import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 512});
const sequence = context.getSequence();

// {w_c_next}
const prompt = "{w_prompt}";
const tokens = model.tokenize(prompt);
const options = {probabilities: true};
for await (const output of sequence.evaluateWithMetadata(tokens, options)) {
  const {probabilities} = output;
  console.log(`"${prompt}" ... 8 likely tokens, of ${probabilities.size}:`);
  for (const [token, probability] of [...probabilities].slice(0, 8)) {
    const piece = JSON.stringify(model.detokenize([token])).padEnd(14);
    const percent = (probability * 100).toFixed(1).padStart(5);
    const bar = "#".repeat(Math.round(probability * 40));
    console.log(`  ${piece} ${percent}%  ${bar}`);
  }
  break;
}
""",
    "temperature.mjs": """import {LlamaCompletion} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 512});
const completion = new LlamaCompletion({
  contextSequence: context.getSequence(),
});

// {w_c_temp}
const request = "{w_name}";
for (const temperature of [0, 1.2]) {
  console.log(`temperature ${temperature}:`);
  for (const seed of [1, 2, 3]) {
    const text = await completion.generateCompletion(request, {
      temperature,
      seed,
      maxTokens: 12,
    });
    console.log(`  seed ${seed}: ${text.trim().split("\\n")[0]}`);
  }
}
""",
    "invent.mjs": """import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 2048});

const ask =
  "{w_ask1}" +
  "{w_ask2}";
const doubt = "{w_doubt}";
const questions = [ask, `${ask} ${doubt}`];
for (const question of questions) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
  });
  const answer = await session.prompt(question, {
    temperature: 0,
    maxTokens: 120,
  });
  console.log(`> ${question}\\n${answer}\\n`);
  session.dispose();
}
""",
    "model-info.mjs": """import {loadModel} from "./lib/model.mjs";

const model = await loadModel();

// {w_c_file}
const {general, tokenizer} = model.fileInfo.metadata;
console.log(`name:            ${general.name}`);
console.log(`size label:      ${general.size_label} parameters`);
const gigabytes = (model.size / 1e9).toFixed(2);
console.log(`file:            ${gigabytes} GB (4-bit quantized)`);
console.log(`vocabulary:      ${tokenizer.ggml.tokens.length} tokens`);
console.log(`context window:  ${model.trainContextSize} tokens`);
""",
    # Projects
    "count.mjs": """import {loadModel} from "./lib/model.mjs";

const model = await loadModel();

// {w_c_price}
const dollarsPerMillion = 3;

// {w_c_count}
const text = process.argv.slice(2).join(" ");
const tokens = model.tokenize(text).length;
const words = text.trim().split(/\\s+/).length;
const perWord = (tokens / words).toFixed(2);
const price = ((tokens * dollarsPerMillion) / 1e6).toFixed(6);
console.log(`${words} words -> ${tokens} tokens (${perWord} per word)`);
console.log(`at $${dollarsPerMillion} per million tokens: $${price}`);
""",
    "generate.mjs": """import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 512});
const sequence = context.getSequence();

// {w_c_loop}
const prompt = model.tokenize("{w_prompt}");
let step = 0;
const options = {confidence: true};
for await (const output of sequence.evaluateWithMetadata(prompt, options)) {
  const piece = JSON.stringify(model.detokenize([output.token])).padEnd(14);
  const percent = (output.confidence * 100).toFixed(1);
  console.log(`step ${++step}: ${piece} ${percent}%`);
  if (step === 8) {
    break;
  }
}
""",
    "bigram.mjs": """// {w_c_bigram}
const corpus = [
{w_corpus}
];
const words = corpus.join(" ").split(" ");

const next = new Map();
for (let i = 0; i < words.length - 1; i++) {
  const followers = next.get(words[i]) ?? new Map();
  followers.set(words[i + 1], (followers.get(words[i + 1]) ?? 0) + 1);
  next.set(words[i], followers);
}

function show(word) {
  const followers = [...next.get(word)].sort((a, b) => b[1] - a[1]);
  const total = followers.reduce((sum, [, count]) => sum + count, 0);
  return followers
    .map(([w, count]) => `${w} ${Math.round((100 * count) / total)}%`)
    .join(", ");
}

// A small seeded random generator (mulberry32), so you get the book's
// sentences.
let seed = 2026;
function random() {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

function pick(word) {
  const followers = [...next.get(word)];
  const total = followers.reduce((sum, [, count]) => sum + count, 0);
  let left = random() * total;
  for (const [w, count] of followers) {
    left -= count;
    if (left < 0) {
      return w;
    }
  }
  return followers.at(-1)[0];
}

console.log(`after "{w_start}": ${show("{w_start}")}`);
for (let line = 0; line < 3; line++) {
  let word = "{w_start}";
  const sentence = [word];
  while (word !== "." && sentence.length < 12) {
    word = pick(word);
    sentence.push(word);
  }
  console.log(sentence.join(" "));
}
""",
}

RUNS = [
    ("tokens.sh", "node tokens.mjs"),
    ("next.sh", "node next.mjs"),
    ("temperature.sh", "node temperature.mjs"),
    ("invent.sh", "node invent.mjs"),
    ("model-info.sh", "node model-info.mjs"),
    ("projects/count.sh", "node count.mjs \"The café opens at eight and sells coffee, tea and cake.\" && "
                          "node count.mjs \"يفتح المقهى في الثامنة ويبيع القهوة والشاي والكيك.\""),
    ("projects/generate.sh", "node generate.mjs"),
    ("projects/bigram.sh", "node bigram.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
