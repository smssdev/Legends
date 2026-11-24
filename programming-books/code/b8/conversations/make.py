"""Writes and runs the examples of Book 8, chapter "Conversations, Files and Images", in English and Arabic:
a conversation that remembers because the program sends its history (and grows in cost every turn), the same
question without the history, an image and a PDF sent as content blocks, and the error for an image that says
it is something else. Then a folder of images described, a history trimmed to a token budget, and two versions
of a contract compared.
Run: python3 make.py   (needs Node 22, Pillow and reportlab; B8_LANG=en runs one edition)
"""
import io
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw
from reportlab.lib.pagesizes import A5
from reportlab.pdfgen import canvas

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

SALES = [("Jan", 410), ("Feb", 380), ("Mar", 455), ("Apr", 520), ("May", 610), ("Jun", 590)]


def chart():
    """A small bar chart of the café's monthly sales, the image the chapter sends."""
    img = Image.new("RGB", (640, 400), "white")
    d = ImageDraw.Draw(img)
    d.text((20, 15), "Bit Cafe - cups sold per month, 2026", fill="black")
    for i, (month, cups) in enumerate(SALES):
        x = 60 + i * 95
        top = 360 - cups // 2
        d.rectangle([x, top, x + 60, 360], fill=(90, 70, 200))
        d.text((x + 15, top - 16), str(cups), fill="black")
        d.text((x + 18, 368), month, fill="black")
    d.line([40, 360, 620, 360], fill="black")
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()


def receipt():
    img = Image.new("RGB", (300, 360), "white")
    d = ImageDraw.Draw(img)
    for i, line in enumerate(["BIT CAFE", "", "Latte large    45.00", "Croissant      30.00",
                              "Water          10.00", "", "TOTAL          85.00", "Paid: card"]):
        d.text((30, 30 + i * 30), line, fill="black")
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()


CONTRACT = [
    ["SUPPLY AGREEMENT", "", "Between Bit Cafe (the Buyer) and Nile Beans Ltd (the Supplier).", "",
     "1. The Supplier delivers 40 kg of roasted coffee every Monday.",
     "2. The Buyer pays within 30 days of each delivery.",
     "3. Late payment carries a fee of 2% per month."],
    ["4. Either party may end this agreement with 60 days' written notice.",
     "5. Prices are fixed until 31 March 2027.",
     "6. The Supplier replaces any damaged bag within 2 working days."],
]


def contract(changes=None):
    """The supplier's contract, two pages; changes replaces some lines, for the second version."""
    pages = [list(p) for p in CONTRACT]
    for (page, line), text in (changes or {}).items():
        pages[page][line] = text
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A5, invariant=1)
    for lines in pages:
        y = 540
        for line in lines:
            c.drawString(40, y, line)
            y -= 22
        c.showPage()
    c.save()
    return buf.getvalue()


def binaries(lang):
    return {
        "files/sales.png": chart(),
        "files/receipt.png": receipt(),
        "files/contract.pdf": contract(),
        "files/contract-v2.pdf": contract({(0, 5): "2. The Buyer pays within 15 days of each delivery.",
                                           (1, 0): "4. Either party may end this agreement with 30 days' written notice."}),
    }


REPLIES = {
    "en": [
        {"when": {"text": "my name is mona", "history": False}, "text": "Nice to meet you, Mona! A café is a "
         "lovely thing to run. How can I help?"},
        {"when": {"text": "name for a new drink", "history": True}, "text": "Since it's for your café: \"Bit Bloom\" "
         "(a rose latte), \"Nile Breeze\" (iced mint tea) or \"Mona's Morning\" (a honey cappuccino)."},
        {"when": {"text": "what is my name", "history": True}, "text": "Your name is Mona, and you run a café."},
        {"when": {"text": "what is my name", "history": False}, "text": "I don't know your name: this is the "
         "start of our conversation, and you haven't told me yet."},
        {"when": "what does this chart show", "text": "Cups sold per month at Bit Cafe in the first half of 2026: "
         "410 in January, 380 in February, 455 in March, 520 in April, 610 in May and 590 in June. Sales dipped in "
         "February, then grew for three months to a peak in May, with a small fall in June."},
        {"when": "what is on this receipt", "text": "A large latte (45.00), a croissant (30.00) and a water "
         "(10.00): 85.00 in total, paid by card."},
        {"when": "obligations of the buyer", "text": "The Buyer must pay within 30 days of each delivery (clause "
         "2, page 1); late payment costs 2% a month (clause 3, page 1); and ending the agreement needs 60 days' "
         "written notice (clause 4, page 2)."},
        {"when": "what changed between", "text": "Two clauses changed. Payment is now due within 15 days of each "
         "delivery instead of 30 (clause 2), and the notice period to end the agreement is now 30 days instead "
         "of 60 (clause 4). Everything else is the same."},
    ],
    "ar": [
        {"when": {"text": "اسمي منى", "history": False}, "text": "تشرفت بمعرفتك يا منى! إدارة مقهى شيء جميل. "
         "كيف أستطيع مساعدتك؟"},
        {"when": {"text": "اسماً لمشروب جديد", "history": True}, "text": "بما أنه لمقهاك: «زهرة بِت» (لاتيه "
         "بالورد)، أو «نسمة النيل» (شاي بالنعناع مثلج)، أو «صباح منى» (كابتشينو بالعسل)."},
        {"when": {"text": "ما اسمي", "history": True}, "text": "اسمك منى، وتديرين مقهى."},
        {"when": {"text": "ما اسمي", "history": False}, "text": "لا أعرف اسمك: هذه بداية محادثتنا، ولم "
         "تخبرني به بعد."},
        {"when": "ماذا يُظهر هذا الرسم", "text": "عدد الأكواب المبيعة شهرياً في مقهى بِت في النصف الأول من 2026: "
         "410 في يناير، و380 في فبراير، و455 في مارس، و520 في أبريل، و610 في مايو، و590 في يونيو. انخفضت "
         "المبيعات في فبراير، ثم نمت ثلاثة أشهر حتى ذروتها في مايو، مع تراجع صغير في يونيو."},
        {"when": "ما في هذا الإيصال", "text": "لاتيه كبير (45.00)، وكرواسون (30.00)، وماء (10.00): 85.00 "
         "إجمالاً، دُفعت بالبطاقة."},
        {"when": "التزامات المشتري", "text": "على المشتري أن يدفع خلال 30 يوماً من كل توريد (البند 2، الصفحة "
         "1)؛ والتأخير يكلّف 2% شهرياً (البند 3، الصفحة 1)؛ وإنهاء الاتفاق يحتاج إشعاراً كتابياً قبل 60 يوماً "
         "(البند 4، الصفحة 2)."},
        {"when": "ما الذي تغيّر بين", "text": "تغيّر بندان. صار الدفع مستحقاً خلال 15 يوماً من كل توريد بدل 30 "
         "(البند 2)، وصارت مدة الإشعار لإنهاء الاتفاق 30 يوماً بدل 60 (البند 4). وكل شيء آخر كما هو."},
    ],
}

T = {
    "en": dict(
        w_replies=json.dumps({"replies": REPLIES["en"]}, ensure_ascii=False, indent=2),
        w_turns=json.dumps(["My name is Mona and I run a café.", "Suggest a name for a new drink.",
                            "What is my name?"], ensure_ascii=False, indent=2),
        w_name="What is my name?",
        w_chart="What does this chart show? Give the numbers.",
        w_receipt="What is on this receipt?",
        w_pdf="What are the obligations of the Buyer? Name the clause and page of each.",
        w_diff="What changed between the first contract and the second?",
        w_c_chat="The app keeps the conversation for you; a program sends it every time.",
        w_c_forget="The same question, without the history.",
        w_c_image="An image is a content block, sent next to the question.",
        w_c_pdf="A PDF is a document block: Claude reads its text and its pages.",
        w_c_mime="An image that says it is something else.",
        w_c_describe="Every image in a folder, with the media type from its extension.",
        w_c_trim="Drop the oldest turns until the conversation fits a budget.",
        w_c_compare="Two documents in one message, each with a title to refer to.",
        w_turn="turn", w_kept="kept",
    ),
    "ar": dict(
        w_replies=json.dumps({"replies": REPLIES["ar"]}, ensure_ascii=False, indent=2),
        w_turns=json.dumps(["اسمي منى وأدير مقهى.", "اقترح اسماً لمشروب جديد.", "ما اسمي؟"], ensure_ascii=False,
                           indent=2),
        w_name="ما اسمي؟",
        w_chart="ماذا يُظهر هذا الرسم؟ أعطِ الأرقام.",
        w_receipt="ما في هذا الإيصال؟",
        w_pdf="ما التزامات المشتري؟ اذكر البند والصفحة لكل منها.",
        w_diff="ما الذي تغيّر بين العقد الأول والثاني؟",
        w_c_chat="التطبيق يحفظ المحادثة عنك؛ والبرنامج يرسلها في كل مرة.",
        w_c_forget="السؤال نفسه، بلا السجل.",
        w_c_image="الصورة كتلة محتوى، تُرسل بجانب السؤال.",
        w_c_pdf="ملف PDF كتلة مستند: يقرأ Claude نصه وصفحاته.",
        w_c_mime="صورة تقول إنها شيء آخر.",
        w_c_describe="كل صورة في مجلد، ونوعها من امتدادها.",
        w_c_trim="احذف أقدم الأدوار حتى تتسع المحادثة لميزانية.",
        w_c_compare="مستندان في رسالة واحدة، لكل منهما عنوان يُشار إليه به.",
        w_turn="الدور", w_kept="بقي",
    ),
}

FILES = {
    "practice.json": "{w_replies}\n",
    "lib/files.mjs": """import fs from "node:fs";
import path from "node:path";

const TYPES = {
  ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
  ".gif": "image/gif", ".webp": "image/webp",
};

// A file on disk as a content block: images by extension, PDFs as documents.
export function block(file, title) {
  const data = fs.readFileSync(file).toString("base64");
  if (file.endsWith(".pdf")) {
    const source = {type: "base64", media_type: "application/pdf", data};
    return {type: "document", source, title};
  }
  const source = {type: "base64", media_type: TYPES[path.extname(file)], data};
  return {type: "image", source};
}

// The text of a response, whatever other blocks it has.
export function text(response) {
  const blocks = response.content.filter((b) => b.type === "text");
  return blocks.map((b) => b.text).join("");
}
""",
    "chat.mjs": """import Anthropic from "@anthropic-ai/sdk";
import {text} from "./lib/files.mjs";

const client = new Anthropic();
const messages = [];

const turns = {w_turns};

// {w_c_chat}
for (const question of turns) {
  messages.push({role: "user", content: question});
  const response = await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 1000,
    messages,
  });
  messages.push({role: "assistant", content: response.content});
  const used = response.usage.input_tokens;
  console.log(`> ${question}\\n${text(response)}`);
  console.log(`  ({w_turn} ${messages.length / 2}: ${used} tokens in)`);
}
""",
    "forget.mjs": """import Anthropic from "@anthropic-ai/sdk";
import {text} from "./lib/files.mjs";

const client = new Anthropic();

// {w_c_forget}
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: "{w_name}"}],
});
console.log(text(response));
""",
    "image.mjs": """import Anthropic from "@anthropic-ai/sdk";
import {block, text} from "./lib/files.mjs";

const client = new Anthropic();

const question = "{w_chart}";

// {w_c_image}
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: [
    block("files/sales.png"),
    {type: "text", text: question},
  ]}],
});
console.log(text(response));
console.log(`--- ${response.usage.input_tokens} tokens in`);
""",
    "pdf.mjs": """import Anthropic from "@anthropic-ai/sdk";
import {block, text} from "./lib/files.mjs";

const client = new Anthropic();

const question = "{w_pdf}";

// {w_c_pdf}
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: [
    block("files/contract.pdf"),
    {type: "text", text: question},
  ]}],
});
console.log(text(response));
console.log(`--- ${response.usage.input_tokens} tokens in`);
""",
    "mime.mjs": """import Anthropic from "@anthropic-ai/sdk";
import fs from "node:fs";

const client = new Anthropic();

// {w_c_mime}
const data = fs.readFileSync("files/sales.png").toString("base64");
try {
  await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 1000,
    messages: [{role: "user", content: [
      {type: "image", source: {type: "base64", media_type: "image/jpeg", data}},
      {type: "text", text: "{w_chart}"},
    ]}],
  });
} catch (error) {
  const message = error.error?.error?.message;
  console.log(`${error.status} ${error.constructor.name}: ${message}`);
}
""",
    # Projects
    "describe.mjs": """import Anthropic from "@anthropic-ai/sdk";
import {block, text} from "./lib/files.mjs";

const client = new Anthropic();
const questions = {
  "sales.png": "{w_chart}",
  "receipt.png": "{w_receipt}",
};

// {w_c_describe}
for (const [file, question] of Object.entries(questions)) {
  const content = [block(`files/${file}`), {type: "text", text: question}];
  const response = await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 500,
    messages: [{role: "user", content}],
  });
  console.log(`${file}: ${text(response)}\\n`);
}
""",
    "trim.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const model = "claude-opus-5-5";

// {w_c_trim}
export async function trim(messages, budget) {
  let kept = [...messages];
  for (;;) {
    const counted = await client.messages.countTokens({model, messages: kept});
    const size = counted.input_tokens;
    if (size <= budget || kept.length <= 1) return {kept, size};
    kept = kept.slice(2); // one user turn and its answer
  }
}

const history = [];
const long = (words) => words.repeat(20);
for (let i = 1; i <= 6; i++) {
  history.push({role: "user", content: `Question ${i}: ${long("about the menu ")}`});
  history.push({role: "assistant", content: `Answer ${i}: ${long("on the menu ")}`});
}
history.push({role: "user", content: "And the last question?"});
for (const budget of [1000, 400, 150]) {
  const {kept, size} = await trim(history, budget);
  const count = `${kept.length} of ${history.length} messages`;
  console.log(`budget ${String(budget).padStart(4)}: {w_kept} ${count}, ${size} tokens`);
}
""",
    "compare.mjs": """import Anthropic from "@anthropic-ai/sdk";
import {block, text} from "./lib/files.mjs";

const client = new Anthropic();

const question = "{w_diff}";

// {w_c_compare}
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: [
    block("files/contract.pdf", "Contract, first version"),
    block("files/contract-v2.pdf", "Contract, second version"),
    {type: "text", text: question},
  ]}],
});
console.log(text(response));
""",
}

RUNS = [
    ("chat.sh", "node chat.mjs"),
    ("forget.sh", "node forget.mjs"),
    ("image.sh", "node image.mjs"),
    ("pdf.sh", "node pdf.mjs"),
    ("mime.sh", "node mime.mjs"),
    ("projects/describe.sh", "node describe.mjs"),
    ("projects/trim.sh", "node trim.mjs"),
    ("projects/compare.sh", "node compare.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS, binaries=binaries)


if __name__ == "__main__":
    main()
