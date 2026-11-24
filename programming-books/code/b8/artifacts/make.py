"""Writes and runs the examples of Book 8, chapter "Artifacts: Apps, Documents and Diagrams", in English and
Arabic: an artifact (a small HTML app) asked for, saved from the reply, and tested in a real browser; the test
fails on a real bug in the artifact, the failure goes back into the conversation, and the fixed version passes
the same test. Then the code blocks of a reply saved by language, a lint for an artifact (title, labels, no
network), and the whole loop run by code with a limit on attempts.
The artifacts are written for the book and returned by the practice server; the browser tests are real.
Run: python3 make.py   (needs Node 22 and Playwright with Chromium; B8_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402


def page(lang, fixed):
    """The tip calculator. The first version reads the bill with parseInt, which drops the piastres, and has
    no label on the tip field; the second reads it with Number and labels every field."""
    en = lang == "en"
    read = "Number(bill.value)" if fixed else "parseInt(bill.value)"
    tip_label = (f'<label for="tip">{"Tip (%)" if en else "البقشيش (%)"}</label>\n    ' if fixed else "")
    return f"""<!doctype html>
<html lang="{lang}"{'' if en else ' dir="rtl"'}>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{"Tip calculator" if en else "حاسبة البقشيش"}</title>
  <style>
    body {{ font-family: system-ui, sans-serif; max-width: 22rem; margin: 2rem auto; }}
    label, input, output {{ display: block; margin: 0.5rem 0; font-size: 1.1rem; }}
    input {{ width: 100%; padding: 0.4rem; }}
  </style>
</head>
<body>
  <h1>{"Tip calculator" if en else "حاسبة البقشيش"}</h1>
  <form id="form">
    <label for="bill">{"Bill (EGP)" if en else "الفاتورة (جنيه)"}</label>
    <input id="bill" inputmode="decimal" value="0">
    {tip_label}<input id="tip" type="number" value="10">
  </form>
  <output id="result">{"Tip" if en else "البقشيش"}: <span id="tip-amount">0.00</span>,
    {"total" if en else "الإجمالي"}: <span id="total">0.00</span></output>
  <script>
    const bill = document.getElementById("bill");
    const tip = document.getElementById("tip");
    function update() {{
      const amount = {read};
      const share = (amount * Number(tip.value)) / 100;
      document.getElementById("tip-amount").textContent = share.toFixed(2);
      const total = amount + share;
      document.getElementById("total").textContent = total.toFixed(2);
    }}
    document.getElementById("form").addEventListener("input", update);
  </script>
</body>
</html>"""


REPLIES = {
    "en": lambda: [
        {"when": {"text": "tip calculator", "history": False}, "text": "Here is a tip calculator as a single HTML "
         "page: type the bill and the tip percentage, and it shows the tip and the total.\n\n```html\n"
         + page("en", False) + "\n```\n\nSave it as an .html file and open it in a browser."},
        {"when": {"text": "test failed", "history": True}, "text": "You're right. `parseInt` stops at the decimal "
         "point, so 85.50 became 85 and the tip was computed on the wrong amount. `Number` keeps the decimals. "
         "I also added the missing label for the tip field.\n\n```html\n" + page("en", True) + "\n```"},
        {"when": "diagram of how an order", "text": "```mermaid\nflowchart LR\n  A[Customer orders] --> "
         "B[Barista makes drink]\n  B --> C{Right drink?}\n  C -- yes --> D[Served]\n  C -- no --> B\n```"},
    ],
    "ar": lambda: [
        {"when": {"text": "حاسبة بقشيش", "history": False}, "text": "إليك حاسبة بقشيش في صفحة HTML واحدة: اكتب "
         "الفاتورة ونسبة البقشيش، فتعرض البقشيش والإجمالي.\n\n```html\n" + page("ar", False) + "\n```\n\nاحفظها "
         "في ملف ‎.html وافتحها في متصفح."},
        {"when": {"text": "فشل الاختبار", "history": True}, "text": "معك حق. `parseInt` يتوقف عند العلامة "
         "العشرية، فصارت 85.50 هي 85 وحُسب البقشيش على المبلغ الخطأ. أما `Number` فيحتفظ بالكسور. وأضفت "
         "أيضاً التسمية الناقصة لحقل البقشيش.\n\n```html\n" + page("ar", True) + "\n```"},
        {"when": "مخططاً لمسار الطلب", "text": "```mermaid\nflowchart RL\n  A[الزبون يطلب] --> B[الباريستا "
         "يحضّر المشروب]\n  B --> C{المشروب صحيح؟}\n  C -- نعم --> D[يُقدَّم]\n  C -- لا --> B\n```"},
    ],
}

T = {
    "en": dict(
        w_ask="Make me a tip calculator as one HTML page: a field for the bill in EGP, a field for the tip "
              "percentage, and the tip and the total, updated as I type.",
        w_failed="The test failed: {failure}. Please fix the page.",
        w_diagram="Draw a diagram of how an order flows at the café, as Mermaid.",
        w_c_ask="Ask for an artifact, and save the code block from the reply.",
        w_c_check="Test an artifact in a real browser: type a bill with piastres, read the result.",
        w_c_fix="Send the failure back into the same conversation, and save the new version.",
        w_c_blocks="Every code block in a reply, saved to a file named for its language.",
        w_c_lint="Checks any artifact should pass before it is shared.",
        w_c_loop="Ask, test, send the failure back: at most three attempts, then a person looks.",
        w_gave="bill 85.50 at 10% gave tip $tip and total $total; expected 8.55 and 94.05", w_sep=", ",
        w_saved="saved", w_lines="lines", w_attempt="attempt", w_give_up="still failing: a person should look",
        w_has_title="has a title", w_labelled="every input has a label", w_offline="makes no network requests",
    ),
    "ar": dict(
        w_ask="اصنع لي حاسبة بقشيش في صفحة HTML واحدة: حقل للفاتورة بالجنيه، وحقل لنسبة البقشيش، والبقشيش "
              "والإجمالي، يتحدثان وأنا أكتب.",
        w_failed="فشل الاختبار: {failure}. أصلح الصفحة من فضلك.",
        w_diagram="ارسم مخططاً لمسار الطلب في المقهى، بصيغة Mermaid.",
        w_c_ask="اطلب artifact، واحفظ كتلة الكود من الرد.",
        w_c_check="اختبر الـ artifact في متصفح حقيقي: اكتب فاتورة فيها قروش، واقرأ النتيجة.",
        w_c_fix="أعد الإخفاق إلى المحادثة نفسها، واحفظ النسخة الجديدة.",
        w_c_blocks="كل كتلة كود في رد، تُحفظ في ملف مسمّى بلغتها.",
        w_c_lint="فحوص يجب أن يجتازها أي artifact قبل مشاركته.",
        w_c_loop="اطلب، واختبر، وأعد الإخفاق: ثلاث محاولات على الأكثر، ثم ينظر إنسان.",
        w_gave="فاتورة 85.50 بنسبة 10% أعطت بقشيشاً $tip وإجمالياً $total؛ والمتوقع 8.55 و94.05", w_sep="، ",
        w_saved="حُفظ", w_lines="سطراً", w_attempt="المحاولة", w_give_up="ما زال يفشل: يجب أن ينظر إنسان",
        w_has_title="له عنوان", w_labelled="لكل حقل تسمية", w_offline="لا يطلب شيئاً من الشبكة",
    ),
}
for lang in T:
    T[lang]["w_replies"] = json.dumps({"replies": REPLIES[lang]()}, ensure_ascii=False, indent=2)

ARTIFACT = """import Anthropic from "@anthropic-ai/sdk";
import fs from "node:fs";

const client = new Anthropic();

// The request for the artifact, and the message that reports a failed test.
export const REQUEST = "{w_ask}";
export const failed = (failure) => "{w_failed}".replace("{failure}", failure);

export async function ask(messages) {
  const response = await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 8000,
    messages,
  });
  const blocks = response.content.filter((b) => b.type === "text");
  return blocks.map((b) => b.text).join("");
}

// The code blocks of a reply: ```lang ... ```
export function codeBlocks(text) {
  return [...text.matchAll(/```(\\w*)\\n([\\s\\S]*?)\\n```/g)].map(([, lang, code]) => ({lang, code}));
}

export function save(file, code) {
  fs.mkdirSync("artifacts", {recursive: true});
  fs.writeFileSync(`artifacts/${file}`, code + "\\n");
  console.log(`{w_saved} artifacts/${file}: ${code.split("\\n").length} {w_lines}`);
}
"""

CHECK = """import {chromium} from "playwright";
import path from "node:path";

// {w_c_check}
export async function check(file) {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto(`file://${path.resolve(file)}`);
  await page.fill("#bill", "85.50");
  await page.fill("#tip", "10");
  const tip = await page.textContent("#tip-amount");
  const total = await page.textContent("#total");
  await browser.close();
  const ok = tip === "8.55" && total === "94.05";
  const failure = "{w_gave}".replace("$tip", tip).replace("$total", total);
  return {ok, failure: ok ? "" : failure};
}

if (process.argv[1].endsWith("check.mjs")) {
  const {ok, failure} = await check(process.argv[2]);
  console.log(ok ? `PASS ${process.argv[2]}` : `FAIL ${process.argv[2]}: ${failure}`);
}
"""

FILES = {
    "practice.json": "{w_replies}\n",
    "lib/artifact.mjs": ARTIFACT,
    "check.mjs": CHECK,
    "make.mjs": """import {ask, codeBlocks, REQUEST, save} from "./lib/artifact.mjs";

// {w_c_ask}
const reply = await ask([{role: "user", content: REQUEST}]);
const [html] = codeBlocks(reply).filter((b) => b.lang === "html");
save("tip-v1.html", html.code);
""",
    "fix.mjs": """import {ask, codeBlocks, failed, REQUEST, save} from "./lib/artifact.mjs";
import {check} from "./check.mjs";

// {w_c_fix}
const messages = [{role: "user", content: REQUEST}];
messages.push({role: "assistant", content: await ask(messages)});
const {failure} = await check("artifacts/tip-v1.html");
messages.push({role: "user", content: failed(failure)});
const reply = await ask(messages);
const [html] = codeBlocks(reply).filter((b) => b.lang === "html");
save("tip-v2.html", html.code);
""",
    # Projects
    "blocks.mjs": """import {ask, codeBlocks, save} from "./lib/artifact.mjs";

const EXTENSIONS = {html: "html", mermaid: "mmd", js: "js", css: "css", svg: "svg"};

// {w_c_blocks}
const reply = await ask([{role: "user", content: "{w_diagram}"}]);
for (const [i, {lang, code}] of codeBlocks(reply).entries()) {
  save(`block-${i + 1}.${EXTENSIONS[lang] ?? "txt"}`, code);
}
""",
    "lint.mjs": """import {chromium} from "playwright";
import path from "node:path";

// {w_c_lint}
async function lint(file) {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const requests = [];
  page.on("request", (r) => r.url().startsWith("file:") || requests.push(r.url()));
  await page.goto(`file://${path.resolve(file)}`);
  const results = {
    "{w_has_title}": (await page.title()).trim().length > 0,
    "{w_labelled}": await page.$$eval("input", (inputs) =>
      inputs.every((i) => i.labels.length > 0 || i.getAttribute("aria-label"))),
    "{w_offline}": requests.length === 0,
  };
  await browser.close();
  return results;
}

for (const file of ["artifacts/tip-v1.html", "artifacts/tip-v2.html"]) {
  const results = await lint(file);
  const failed = Object.entries(results).filter(([, ok]) => !ok).map(([name]) => name);
  console.log(`${file}: ${failed.length ? `FAIL (${failed.join("; ")})` : "PASS"}`);
}
""",
    "loop.mjs": """import {ask, codeBlocks, failed, REQUEST, save} from "./lib/artifact.mjs";
import {check} from "./check.mjs";

// {w_c_loop}
const messages = [{role: "user", content: REQUEST}];
for (let attempt = 1; attempt <= 3; attempt++) {
  const reply = await ask(messages);
  messages.push({role: "assistant", content: reply});
  const [html] = codeBlocks(reply).filter((b) => b.lang === "html");
  save(`loop-${attempt}.html`, html.code);
  const {ok, failure} = await check(`artifacts/loop-${attempt}.html`);
  console.log(`{w_attempt} ${attempt}: ${ok ? "PASS" : `FAIL{w_sep}${failure}`}`);
  if (ok) process.exit(0);
  messages.push({role: "user", content: failed(failure)});
}
console.log("{w_give_up}");
""",
}

RUNS = [
    ("make.sh", "node make.mjs"),
    ("check-v1.sh", "node check.mjs artifacts/tip-v1.html"),
    ("fix.sh", "node fix.mjs"),
    ("check-v2.sh", "node check.mjs artifacts/tip-v2.html"),
    ("projects/blocks.sh", "node blocks.mjs && cat artifacts/block-1.mmd"),
    ("projects/lint.sh", "node lint.mjs"),
    ("projects/loop.sh", "node loop.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS, extra=("playwright",))


if __name__ == "__main__":
    main()
