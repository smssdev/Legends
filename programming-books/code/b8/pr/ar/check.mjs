import {execFileSync} from "node:child_process";
import fs from "node:fs";

// قبل المراجعة: اسم الفرع، وكل رسالة حفظ، والوصف.
const git = (...args) => execFileSync("git", args, {encoding: "utf8"}).trim();
const branch = git("branch", "--show-current");
const messages = git("log", "main..HEAD", "--format=%s").split("\n").filter(Boolean);
const body = fs.readFileSync("PR.md", "utf8");
const sections = [...fs.readFileSync(".github/pull_request_template.md", "utf8").matchAll(/^## .+$/gm)];
const problems = {
  "اسم الفرع": /^(fix|feat|docs|chore)\/\d+-[a-z0-9-]+$/.test(branch) ? [] : [branch],
  "رسائل الحفظ": messages.filter((m) => !/^(feat|fix|docs|refactor|test|chore)(\([a-z-]+\))?: .+/.test(m)),
  "الوصف": [
    ...sections.filter(([s]) => !body.includes(s)).map(([s]) => `قسم ناقص: ${s}`),
    ...(/#\d+/.test(body) ? [] : ["لا يغلق مهمة"]),
  ],
};
for (const [what, found] of Object.entries(problems)) {
  console.log(`${what.padEnd(16)} ${found.length ? `يحتاج عملاً: ${found.join("; ")}` : "سليم"}`);
}
