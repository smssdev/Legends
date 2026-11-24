"""Writes and runs the examples of Book 8, chapter "Projects and Knowledge", in English and Arabic: a project
as instructions and knowledge given to every chat, built with the API: the instructions as the system prompt,
the knowledge as documents marked for caching, so the first chat writes them to the cache and the next ones
read them back at a fraction of the price. Then a project loaded from a folder, a knowledge budget, and two
projects that answer the same question differently because of their instructions.
Run: python3 make.py   (needs Node 22; B8_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

KNOWLEDGE = {
    "en": {
        "menu.md": "# Bit Cafe menu (2026)\n\n" + "\n".join(
            f"- {name}: {price} EGP. {note}" for name, price, note in [
                ("Espresso", 35, "Single shot, Ethiopian beans."), ("Latte", 45, "Large; oat milk +10."),
                ("Rose latte", 55, "New in spring; contains rose syrup."), ("Mint tea", 30, "Hot or iced."),
                ("Honey cappuccino", 50, "With Sinai honey."), ("Croissant", 30, "Baked every morning."),
                ("Date cake", 40, "Contains nuts."), ("Water", 10, "Still or sparkling."),
            ]) + "\n\nAll prices include VAT. Oat milk, soy milk and lactose-free milk are available.\n" * 1,
        "policies.md": "# Policies\n\n"
                       "- Opening hours: 7:00 to 23:00 every day; Fridays from 13:00.\n"
                       "- Refunds: a drink that is wrong is remade or refunded at once, no questions asked.\n"
                       "- Allergies: the date cake contains nuts; ask the barista about any other allergen.\n"
                       "- Wi-Fi: free for customers; the password is on the receipt.\n"
                       "- Loyalty card: the tenth drink is free; cards work in every branch.\n"
                       "- Branches: Zamalek, Maadi and Heliopolis.\n" + (
                           "- Groups of more than ten people should book a day ahead by phone.\n"
                           "- Laptops are welcome all day except Friday afternoons.\n"
                           "- Pets on a lead are welcome on the terrace.\n"),
        "voice.md": "# How we write\n\nWarm, short and plain. We say 'we', never 'the company'. No exclamation "
                    "marks, no emojis, no slang. We answer the question first, then add one helpful detail. "
                    "When we do not know, we say so and offer to ask a colleague.\n",
    },
    "ar": {
        "menu.md": "# قائمة مقهى بِت (2026)\n\n" + "\n".join(
            f"- {name}: {price} جنيهاً. {note}" for name, price, note in [
                ("إسبريسو", 35, "جرعة واحدة، بن إثيوبي."), ("لاتيه", 45, "كبير؛ حليب الشوفان +10."),
                ("لاتيه بالورد", 55, "جديد في الربيع؛ فيه شراب الورد."), ("شاي بالنعناع", 30, "ساخن أو مثلج."),
                ("كابتشينو بالعسل", 50, "بعسل سيناء."), ("كرواسون", 30, "يُخبز كل صباح."),
                ("كعكة التمر", 40, "فيها مكسرات."), ("ماء", 10, "عادي أو فوار."),
            ]) + "\n\nكل الأسعار شاملة الضريبة. وحليب الشوفان والصويا والخالي من اللاكتوز متاح.\n",
        "policies.md": "# السياسات\n\n"
                       "- مواعيد العمل: من 7:00 إلى 23:00 يومياً؛ والجمعة من 13:00.\n"
                       "- الاسترداد: المشروب الخاطئ يُعاد تحضيره أو يُسترد ثمنه فوراً، بلا أسئلة.\n"
                       "- الحساسية: كعكة التمر فيها مكسرات؛ واسأل الباريستا عن أي مادة أخرى.\n"
                       "- الواي فاي: مجاني للزبائن؛ وكلمة المرور على الإيصال.\n"
                       "- بطاقة الولاء: المشروب العاشر مجاني؛ والبطاقات تعمل في كل الفروع.\n"
                       "- الفروع: الزمالك والمعادي ومصر الجديدة.\n" + (
                           "- المجموعات فوق عشرة أشخاص تحجز قبلها بيوم بالهاتف.\n"
                           "- الحواسيب مرحب بها طوال اليوم إلا عصر الجمعة.\n"
                           "- الحيوانات الأليفة المربوطة مرحب بها في الشرفة.\n"),
        "voice.md": "# كيف نكتب\n\nدافئ وقصير وبسيط. نقول «نحن»، لا «الشركة». بلا علامات تعجب، ولا رموز "
                    "تعبيرية، ولا عامية. نجيب عن السؤال أولاً، ثم نضيف تفصيلاً واحداً مفيداً. وحين لا نعرف، نقول "
                    "ذلك ونعرض أن نسأل زميلاً.\n",
    },
}

INSTRUCTIONS = {
    "en": {
        "support": "You answer customers of Bit Cafe. Use only the project's documents. Follow voice.md. If the "
                   "documents do not answer, say you will ask a colleague.",
        "marketing": "You help the Bit Cafe team write posts for social media. Use the menu for facts, and write "
                     "with energy for a young audience. Offer two options.",
    },
    "ar": {
        "support": "أنت تجيب زبائن مقهى بِت. استخدم مستندات المشروع فقط. واتبع voice.md. وإن لم تجب المستندات، "
                   "فقل إنك ستسأل زميلاً.",
        "marketing": "أنت تساعد فريق مقهى بِت في كتابة منشورات لوسائل التواصل. استخدم القائمة للحقائق، واكتب "
                     "بحيوية لجمهور شاب. واعرض خيارين.",
    },
}

REPLIES = {
    "en": [
        {"when": {"text": "rose latte", "system": "social media"}, "text": "1. Spring has a new flavour: our rose "
         "latte, 55 EGP, is here. Come taste it before the season ends.\n2. Coffee, but make it bloom. Rose latte, "
         "55 EGP, at every Bit Cafe."},
        {"when": {"text": "rose latte", "system": "answer customers"}, "text": "Our rose latte costs 55 EGP. It "
         "contains rose syrup, so tell the barista if you would like it less sweet."},
        {"when": {"text": "nuts", "system": "answer customers"}, "text": "Yes: our date cake contains nuts. For "
         "any other allergen, please ask the barista, who can check each item for you."},
        {"when": {"text": "parking", "system": "answer customers"}, "text": "I'm not sure: our documents don't "
         "say. I will ask a colleague and come back to you."},
        {"when": "rose latte", "text": "A rose latte is a latte flavoured with rose syrup or rose water. Prices "
         "vary by café; I don't know what Bit Cafe charges."},
    ],
    "ar": [
        {"when": {"text": "لاتيه بالورد", "system": "وسائل التواصل"}, "text": "1. للربيع نكهة جديدة: لاتيه بالورد "
         "عندنا، بـ 55 جنيهاً. تعالَ وجرّبه قبل نهاية الموسم.\n2. قهوتك هذا الربيع تتفتح: لاتيه بالورد، 55 "
         "جنيهاً، في كل فروع بِت."},
        {"when": {"text": "لاتيه بالورد", "system": "تجيب زبائن"}, "text": "سعر اللاتيه بالورد عندنا 55 جنيهاً. "
         "وفيه شراب الورد، فأخبر الباريستا إن أردته أقل حلاوة."},
        {"when": {"text": "مكسرات", "system": "تجيب زبائن"}, "text": "نعم: كعكة التمر عندنا فيها مكسرات. ولأي "
         "مادة أخرى، اسأل الباريستا من فضلك، فهو يستطيع فحص كل صنف لك."},
        {"when": {"text": "موقف", "system": "تجيب زبائن"}, "text": "لست متأكداً: مستنداتنا لا تذكر ذلك. سأسأل "
         "زميلاً وأعود إليك."},
        {"when": "لاتيه بالورد", "text": "اللاتيه بالورد لاتيه منكّه بشراب الورد أو ماء الورد. وتختلف الأسعار "
         "بين المقاهي؛ ولا أعرف سعره في مقهى بِت."},
    ],
}

RECIPES = [  # drink, espresso shots, milk ml, extra, temperature C, cup ml
    ("latte", "لاتيه", 2, 250, ("", ""), 65, 350),
    ("rose latte", "لاتيه بالورد", 2, 230, ("20 ml rose syrup", "20 مل شراب ورد"), 65, 350),
    ("honey cappuccino", "كابتشينو بالعسل", 2, 150, ("15 g Sinai honey", "15 غ عسل سيناء"), 62, 250),
    ("flat white", "فلات وايت", 2, 120, ("", ""), 60, 180),
    ("mocha", "موكا", 2, 200, ("25 g dark chocolate", "25 غ شوكولاتة داكنة"), 65, 350),
    ("iced latte", "لاتيه مثلج", 2, 200, ("150 g ice", "150 غ ثلج"), 4, 400),
    ("cortado", "كورتادو", 2, 60, ("", ""), 58, 120),
    ("cardamom latte", "لاتيه بالهيل", 2, 230, ("2 g ground cardamom", "2 غ هيل مطحون"), 65, 350),
]


def recipes(lang):
    lines = ["# Recipes for baristas\n" if lang == "en" else "# وصفات للباريستا\n"]
    for en, ar, shots, milk, extra, temp, cup in RECIPES:
        if lang == "en":
            lines.append(f"## {en.title()}\n- Cup: {cup} ml.\n- Espresso: {shots} shots (36 g), extracted in "
                         f"25 to 30 seconds.\n- Milk: {milk} ml, steamed to {temp} C." if temp > 10 else
                         f"## {en.title()}\n- Cup: {cup} ml.\n- Espresso: {shots} shots (36 g), cooled.\n"
                         f"- Milk: {milk} ml, cold.")
            if extra[0]:
                lines.append(f"- Add {extra[0]} to the cup before the espresso.")
            lines.append("- Serve at once; a drink that waits more than two minutes is remade.\n")
        else:
            lines.append(f"## {ar}\n- الكوب: {cup} مل.\n- الإسبريسو: {shots} جرعة (36 غ)، تُستخلص في 25 إلى "
                         f"30 ثانية.\n- الحليب: {milk} مل، مبخّر حتى {temp} درجة." if temp > 10 else
                         f"## {ar}\n- الكوب: {cup} مل.\n- الإسبريسو: {shots} جرعة (36 غ)، مبرّدة.\n"
                         f"- الحليب: {milk} مل، بارد.")
            if extra[1]:
                lines.append(f"- أضف {extra[1]} إلى الكوب قبل الإسبريسو.")
            lines.append("- يُقدّم فوراً؛ والمشروب الذي ينتظر أكثر من دقيقتين يُحضّر من جديد.\n")
    return "\n".join(lines)


for lang in ("en", "ar"):
    KNOWLEDGE[lang]["recipes.md"] = recipes(lang)

T = {}
for lang in ("en", "ar"):
    words = {
        "en": dict(
            w_q_price="How much is the rose latte?", w_q_nuts="Does anything contain nuts?",
            w_q_park="Is there parking at the Zamalek branch?", w_q_post="Write a post about the rose latte.",
            w_c_project="A project: instructions for every chat, and knowledge, marked for the cache.",
            w_c_chats="Three chats in the same project: the knowledge is written to the cache once, then read.",
            w_c_plain="The same question with no project: no instructions, no knowledge.",
            w_c_load="A project from a folder: instructions.md, and every file in knowledge/.",
            w_c_budget="How much of the context the knowledge takes, before any question.",
            w_c_two="One question, two projects: the instructions decide the answer.",
            w_chat="chat", w_written="written to cache", w_read="read from cache",
            w_of="of", w_window="the context window", w_sep=", ", w_new="new", w_files="files:", w_left="left for the conversation",
        ),
        "ar": dict(
            w_q_price="كم سعر اللاتيه بالورد؟", w_q_nuts="هل في أي صنف مكسرات؟",
            w_q_park="هل يوجد موقف سيارات في فرع الزمالك؟", w_q_post="اكتب منشوراً عن اللاتيه بالورد.",
            w_c_project="المشروع: تعليمات لكل محادثة، ومعرفة، موسومة للذاكرة المؤقتة.",
            w_c_chats="ثلاث محادثات في المشروع نفسه: تُكتب المعرفة في الذاكرة المؤقتة مرة، ثم تُقرأ.",
            w_c_plain="السؤال نفسه بلا مشروع: لا تعليمات، ولا معرفة.",
            w_c_load="مشروع من مجلد: instructions.md، وكل ملف في knowledge/.",
            w_c_budget="كم تأخذ المعرفة من السياق، قبل أي سؤال.",
            w_c_two="سؤال واحد، ومشروعان: التعليمات تقرر الجواب.",
            w_chat="المحادثة", w_written="كُتب في الذاكرة المؤقتة", w_read="قُرئ من الذاكرة المؤقتة",
            w_of="من", w_window="نافذة السياق", w_sep="، ", w_new="جديدة", w_files="الملفات:", w_left="يبقى للمحادثة",
        ),
    }[lang]
    words["w_replies"] = json.dumps({"replies": REPLIES[lang]}, ensure_ascii=False, indent=2)
    T[lang] = words

PROJECT = """import Anthropic from "@anthropic-ai/sdk";
import fs from "node:fs";
import path from "node:path";

const client = new Anthropic();
const read = (...parts) => fs.readFileSync(path.join(...parts), "utf8");

// {w_c_project}
export function loadProject(folder) {
  const instructions = read(folder, "instructions.md");
  const dir = path.join(folder, "knowledge");
  const knowledge = fs.readdirSync(dir).sort().map((name) => ({
    type: "text",
    text: `<document name="${name}">\\n${read(dir, name)}</document>`,
  }));
  knowledge.at(-1).cache_control = {type: "ephemeral"};
  return {instructions, knowledge};
}

export async function chat(project, question) {
  return client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 1000,
    system: [{type: "text", text: project.instructions}, ...project.knowledge],
    messages: [{role: "user", content: question}],
  });
}

export function text(response) {
  const blocks = response.content.filter((b) => b.type === "text");
  return blocks.map((b) => b.text).join("");
}
"""


def files(lang):
    out = {"practice.json": "{w_replies}\n", "lib/project.mjs": PROJECT}
    for project, instructions in INSTRUCTIONS[lang].items():
        out[f"{project}/instructions.md"] = instructions + "\n"
        for name, text in KNOWLEDGE[lang].items():
            if project == "support" or name == "menu.md":
                out[f"{project}/knowledge/{name}"] = text
    return out


COMMON = {
    "chats.mjs": """import {chat, loadProject, text} from "./lib/project.mjs";

const support = loadProject("support");

// {w_c_chats}
for (const [i, question] of ["{w_q_price}", "{w_q_nuts}", "{w_q_park}"].entries()) {
  const response = await chat(support, question);
  const u = response.usage;
  console.log(`> ${question}\\n${text(response)}`);
  console.log(`  ({w_chat} ${i + 1}: ${u.cache_creation_input_tokens} {w_written}{w_sep}` +
    `${u.cache_read_input_tokens} {w_read}{w_sep}${u.input_tokens} {w_new})`);
}
""",
    "plain.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// {w_c_plain}
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: "{w_q_price}"}],
});
console.log(response.content[0].text);
""",
    # Projects
    "budget.mjs": """import Anthropic from "@anthropic-ai/sdk";
import {loadProject} from "./lib/project.mjs";

const client = new Anthropic();

// {w_c_budget}
for (const name of ["support", "marketing"]) {
  const {instructions, knowledge} = loadProject(name);
  const {input_tokens: size} = await client.messages.countTokens({
    model: "claude-opus-5-5",
    system: [{type: "text", text: instructions}, ...knowledge],
    messages: [{role: "user", content: "?"}],
  });
  const share = ((size / 1_000_000) * 100).toFixed(3);
  const files = `{w_files} ${knowledge.length}`;
  console.log(`${name.padEnd(10)} ${files}{w_sep}${size} tokens: ${share}% {w_of} {w_window}`);
}
""",
    "two.mjs": """import {chat, loadProject, text} from "./lib/project.mjs";

// {w_c_two}
for (const name of ["support", "marketing"]) {
  const response = await chat(loadProject(name), "{w_q_post}");
  console.log(`[${name}]\\n${text(response)}\\n`);
}
""",
}

RUNS = [
    ("chats.sh", "node chats.mjs"),
    ("plain.sh", "node plain.mjs"),
    ("tree.sh", "find support marketing -type f | sort"),
    ("projects/budget.sh", "node budget.mjs"),
    ("projects/two.sh", "node two.mjs"),
]


def main():
    for lang in ("en", "ar"):
        chapter(HERE, {lang: T[lang]}, {**files(lang), **COMMON}, RUNS)


if __name__ == "__main__":
    main()
