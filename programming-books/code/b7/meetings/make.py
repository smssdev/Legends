"""Writes and runs the examples of Book 7, chapter "Meetings, Emails and Reports", in English and Arabic: a meeting
summarised into decisions and actions and checked against the transcript, an email whose every number is checked
against the facts it was given, and a status report whose every "done" is checked against the commit log. Then
a fact checker for any draft, a change of tone that must keep the facts, and a long thread summarised in parts.
Run: python3 make.py   (needs Node 22 and the book's model; B7_LANG=en runs one edition)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

MEETING_EN = """Mona: Thanks for coming. Three things today: the loyalty card, the new prices, and the Friday hours.
Omar: On the loyalty card, the app work is done except the screen that shows the stamps.
Mona: When can the screen be ready?
Omar: Hassan is on it. Hassan?
Hassan: I can have it by Thursday the 4th of December.
Mona: Good. Decision then: the loyalty card launches on Monday the 8th of December, in both branches.
Sara: Can we launch in the Nasr City branch first, to test it?
Mona: No, both together. Customers move between branches and one card must work everywhere.
Sara: Fine.
Mona: Prices. The large latte goes from 45 to 50 pounds on the 1st of January. Everything else stays.
Omar: Should we tell customers in the app?
Mona: Yes. Sara, please write the notice and send it to me by the 15th of December.
Sara: Will do.
Hassan: What about the cold brew? Some people asked for a lower price.
Mona: Not this time. We will look at it again in March.
Mona: Last thing: Friday hours. We open at 9 instead of 8 from next Friday.
Omar: I will update the hours in the app and on the door.
Mona: Thank you all."""

MEETING_AR = """منى: شكراً لحضوركم. ثلاثة أمور اليوم: بطاقة الولاء، والأسعار الجديدة، ومواعيد الجمعة.
عمر: بالنسبة لبطاقة الولاء، عمل التطبيق انتهى إلا الشاشة التي تعرض الطوابع.
منى: متى تجهز الشاشة؟
عمر: حسن يعمل عليها. حسن؟
حسن: أستطيع إنهاءها يوم الخميس 4 ديسمبر.
منى: جيد. القرار إذن: بطاقة الولاء تنطلق يوم الاثنين 8 ديسمبر، في الفرعين معاً.
سارة: هل نطلقها في فرع مدينة نصر أولاً، للتجربة؟
منى: لا، الفرعان معاً. العملاء يتنقلون بين الفرعين والبطاقة الواحدة يجب أن تعمل في كل مكان.
سارة: حسناً.
منى: الأسعار. اللاتيه الكبير يرتفع من 45 إلى 50 جنيهاً في 1 يناير. وكل شيء آخر يبقى.
عمر: هل نخبر العملاء في التطبيق؟
منى: نعم. سارة، اكتبي الإشعار وأرسليه لي قبل 15 ديسمبر.
سارة: سأفعل.
حسن: وماذا عن الكولد برو؟ بعض الناس طلبوا سعراً أقل.
منى: ليس هذه المرة. سننظر فيه من جديد في مارس.
منى: آخر أمر: مواعيد الجمعة. نفتح في 9 بدل 8 من الجمعة القادمة.
عمر: سأحدّث المواعيد في التطبيق وعلى الباب.
منى: شكراً للجميع."""

LOG = """a41c2e9 feat(loyalty): stamp a card for every paid hot drink
7d0f113 feat(loyalty): free drink on the 10th stamp
c92b801 fix(loyalty): remove the stamp of a refunded drink
e11a6f0 test(loyalty): both branches share one card"""

TASKS = """T1 stamps for paid hot drinks
T2 free drink on the 10th stamp
T3 refunds remove stamps
T4 both branches share the card
T5 the stamps screen in the app
T6 the free drink at checkout"""

T = {
    "en": dict(
        w_meeting=MEETING_EN,
        w_summarise="Summarise this meeting as JSON: the decisions, and the action items, each with owner, task "
                    "and due date (as written in the meeting, or none).",
        w_email_facts="Facts: from the 1st of January the large latte costs 50 pounds instead of 45; every other "
                      "price stays the same; the loyalty card starts on Monday the 8th of December in both branches.",
        w_email="Write a short, friendly email from the café to its customers announcing these facts. At most "
                "120 words. Use only the facts given.",
        w_report="Write a short weekly status report for the loyalty card project from this commit log and task "
                 "list. Say which tasks are done and which remain.",
        w_tone="Rewrite this email in a more formal tone, for a corporate customer. Keep every fact.",
        w_part="Summarise this part of a discussion in at most three lines: the decisions only.",
        w_merge="Here are summaries of the parts of one discussion. Merge them into one list of decisions, "
                "without repeating.",
        w_c_truth="What was actually decided and assigned, written by the person who was there.",
        w_c_check="An owner the meeting never named, or a date it never said, is invented.",
        w_c_numbers="Every number in the email must come from the facts it was given.",
        w_c_done="A task reported as done must have a commit.",
        w_c_facts="The facts of a text: its numbers and its capitalised names.",
        w_c_parts="A thread too long for one request: summarise each part, then merge the summaries.",
    ),
    "ar": dict(
        w_meeting=MEETING_AR,
        w_summarise="لخّص هذا الاجتماع بـ JSON: القرارات، والمهام، لكل منها owner وtask وdue (كما قيل في "
                    "الاجتماع، أو none).",
        w_email_facts="الحقائق: من 1 يناير يصير سعر اللاتيه الكبير 50 جنيهاً بدل 45؛ وكل الأسعار الأخرى تبقى "
                      "كما هي؛ وبطاقة الولاء تبدأ يوم الاثنين 8 ديسمبر في الفرعين.",
        w_email="اكتب رسالة بريد قصيرة لطيفة من المقهى إلى عملائه تعلن هذه الحقائق. 120 كلمة على الأكثر. "
                "استخدم الحقائق المعطاة وحدها.",
        w_report="اكتب تقرير حالة أسبوعياً قصيراً لمشروع بطاقة الولاء من سجل الحفظ وقائمة المهام هذين. قل أي "
                 "المهام انتهت وأيها بقي.",
        w_tone="أعد كتابة هذه الرسالة بنبرة أكثر رسمية، لعميل شركة. احتفظ بكل حقيقة.",
        w_part="لخّص هذا الجزء من نقاش في ثلاثة أسطر على الأكثر: القرارات وحدها.",
        w_merge="هذه ملخصات أجزاء نقاش واحد. ادمجها في قائمة قرارات واحدة، بلا تكرار.",
        w_c_truth="ما تقرر وأُسند فعلاً، يكتبه من حضر.",
        w_c_check="المسؤول الذي لم يسمّه الاجتماع، أو الموعد الذي لم يُقل، مخترع.",
        w_c_numbers="كل رقم في الرسالة يجب أن يأتي من الحقائق المعطاة.",
        w_c_done="المهمة التي يُقال إنها انتهت يجب أن يكون لها حفظ.",
        w_c_facts="حقائق النص: أرقامه.",
        w_c_parts="نقاش أطول من طلب واحد: لخّص كل جزء، ثم ادمج الملخصات.",
    ),
}

TRUTH = {
    "en": """export const TRUTH = {
  decisions: 4,
  rejected: ["launch in one branch first", "a lower price for the cold brew"],
  people: ["Mona", "Omar", "Hassan", "Sara"],
  actions: [
    {owner: "Hassan", task: "stamps screen", due: "4"},
    {owner: "Sara", task: "price notice", due: "15"},
    {owner: "Omar", task: "Friday hours", due: null},
  ],
};
""",
    "ar": """export const TRUTH = {
  decisions: 4,
  rejected: ["الإطلاق في فرع واحد أولاً", "سعر أقل للكولد برو"],
  people: ["منى", "عمر", "حسن", "سارة"],
  actions: [
    {owner: "حسن", task: "شاشة الطوابع", due: "4"},
    {owner: "سارة", task: "إشعار الأسعار", due: "15"},
    {owner: "عمر", task: "مواعيد الجمعة", due: null},
  ],
};
""",
}

ASK = """import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 6144});

// One question in a fresh conversation, at temperature 0.
export async function ask(prompt, options = {}) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
  });
  const answer = await session.prompt(prompt, {
    temperature: 0,
    maxTokens: options.maxTokens ?? 600,
    grammar: options.grammar,
  });
  session.dispose();
  return answer.trim();
}

export {model};
"""

FACTS = """// The numbers in a text (dates, prices, counts), as strings.
export function numbers(text) {
  return new Set(text.match(/\\d+(?:[.,]\\d+)?/g) ?? []);
}

// Numbers in a draft that are not in its sources: invented, or changed.
export function newNumbers(draft, ...sources) {
  const known = new Set(sources.flatMap((source) => [...numbers(source)]));
  return [...numbers(draft)].filter((n) => !known.has(n));
}
"""

FILES = {
    "lib/ask.mjs": ASK,
    "lib/facts.mjs": FACTS,
    "meeting.txt": "{w_meeting}\n",
    "log.txt": LOG + "\n",
    "tasks.txt": TASKS + "\n",
    "summary.mjs": """import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";
import {TRUTH} from "./truth.mjs";

const meeting = fs.readFileSync("meeting.txt", "utf8");
const text = {type: "string"};
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    decisions: {type: "array", items: text},
    actions: {
      type: "array",
      items: {type: "object", properties: {owner: text, task: text, due: text}},
    },
  },
});
const summary = JSON.parse(await ask(`{w_summarise}\\n\\n${meeting}`, {grammar}));
console.log("decisions:");
summary.decisions.forEach((d) => console.log(`  - ${d}`));
console.log("actions:");
summary.actions.forEach((a) => console.log(`  - ${a.owner}: ${a.task} (${a.due})`));

// {w_c_check}
console.log("--- checked against the meeting");
console.log(`decisions: ${summary.decisions.length} listed, ${TRUTH.decisions} made`);
for (const action of summary.actions) {
  const named = TRUTH.people.some((p) => action.owner.includes(p));
  const date = (action.due.match(/\\d+/g) ?? []).every((n) => meeting.includes(n));
  const problems = [!named && "owner not in the meeting", !date && "date not in the meeting"].filter(Boolean);
  console.log(`${problems.length ? "WRONG" : "ok   "} ${action.owner}: ${action.task} ${problems.join(", ")}`);
}
for (const {owner} of TRUTH.actions) {
  if (!summary.actions.some((a) => a.owner.includes(owner))) {
    console.log(`MISSED an action for ${owner}`);
  }
}
for (const idea of TRUTH.rejected) {
  console.log(`(rejected in the meeting: ${idea})`);
}
""",
    "email.mjs": """import {ask} from "./lib/ask.mjs";
import {newNumbers} from "./lib/facts.mjs";

const facts = "{w_email_facts}";
const email = await ask(`{w_email}\\n\\n${facts}`, {maxTokens: 400});
console.log(email);

// {w_c_numbers}
const words = email.split(/\\s+/).length;
const invented = newNumbers(email, facts);
console.log(`--- ${words} words; numbers not in the facts: ${invented.join(", ") || "none"}`);
""",
    "report.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const log = fs.readFileSync("log.txt", "utf8");
const tasks = fs.readFileSync("tasks.txt", "utf8");
const report = await ask(`{w_report}\\n\\n${log}\\n${tasks}`, {maxTokens: 500});
console.log(report);

// {w_c_done}
const done = {T1: "stamp a card", T2: "free drink on the 10th", T3: "refunded", T4: "both branches"};
console.log("--- the truth, from the log");
for (const line of tasks.trim().split("\\n")) {
  const id = line.split(" ")[0];
  const inLog = done[id] ? log.includes(done[id]) : false;
  console.log(`${id} ${inLog ? "done   " : "not done"} ${line.slice(3)}`);
}
""",
    # Projects
    "check.mjs": """import fs from "node:fs";
import {newNumbers} from "./lib/facts.mjs";

// {w_c_facts}
const [draft, ...sources] = process.argv.slice(2).map((file) => fs.readFileSync(file, "utf8"));
const invented = newNumbers(draft, ...sources);
console.log(invented.length ? `numbers not in the sources: ${invented.join(", ")}` : "every number has a source");
""",
    "draft.txt": "{w_draft}\n",
    "facts.txt": "{w_email_facts}\n",
    "tone.mjs": """import {ask} from "./lib/ask.mjs";
import {numbers} from "./lib/facts.mjs";

const facts = "{w_email_facts}";
const friendly = await ask(`{w_email}\\n\\n${facts}`, {maxTokens: 400});
const formal = await ask(`{w_tone}\\n\\n${friendly}`, {maxTokens: 400});
console.log(formal);

const before = numbers(friendly);
const after = numbers(formal);
const lost = [...before].filter((n) => !after.has(n));
const added = [...after].filter((n) => !before.has(n));
console.log(`--- numbers lost: ${lost.join(", ") || "none"}; added: ${added.join(", ") || "none"}`);
""",
    "thread.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

// {w_c_parts}
const lines = fs.readFileSync("meeting.txt", "utf8").trim().split("\\n");
const parts = [lines.slice(0, 9), lines.slice(9, 15), lines.slice(15)].map((p) => p.join("\\n"));
const summaries = [];
for (const [i, part] of parts.entries()) {
  summaries.push(await ask(`{w_part}\\n\\n${part}`, {maxTokens: 150}));
  console.log(`part ${i + 1}: ${summaries.at(-1).replace(/\\s*\\n\\s*/g, " / ")}`);
}
console.log("--- merged");
console.log(await ask(`{w_merge}\\n\\n${summaries.join("\\n\\n")}`, {maxTokens: 300}));
""",
}

T["en"]["w_draft"] = ("Dear customers, from the 1st of January our large latte will cost 55 pounds. "
                      "The loyalty card starts on the 8th of December, and your 10th coffee is free.")
T["ar"]["w_draft"] = ("عملاءنا الأعزاء، من 1 يناير سيصير سعر اللاتيه الكبير 55 جنيهاً. "
                      "وبطاقة الولاء تبدأ في 8 ديسمبر، والقهوة العاشرة مجانية.")

RUNS = [
    ("summary.sh", "node summary.mjs"),
    ("email.sh", "node email.mjs"),
    ("report.sh", "node report.mjs"),
    ("projects/check.sh", "node check.mjs draft.txt facts.txt"),
    ("projects/tone.sh", "node tone.mjs"),
    ("projects/thread.sh", "node thread.mjs"),
]


def main():
    # What really happened in the meeting, in each language, for the checks.
    FILES["truth.mjs"] = "{w_truth}"
    for lang, truth in TRUTH.items():
        T[lang]["w_truth"] = truth
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
