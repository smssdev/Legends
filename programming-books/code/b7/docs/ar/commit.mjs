import {execSync} from "node:child_process";
import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {lintCommit} from "./lib/lint.mjs";

const git = (command) => execSync(`git ${command}`, {cwd: "repo", encoding: "utf8"}).trim();
fs.rmSync("repo", {recursive: true, force: true});
fs.mkdirSync("repo");
git("init -q -b main");
git("config user.name Bit && git config user.email bit@example.com");
fs.copyFileSync("price.mjs", "repo/price.mjs");
git("add price.mjs && git commit -q -m 'feat(price): line prices with a bulk discount'");

// The change: the cap on the discount drops from 5000 to 3000.
const changed = fs.readFileSync("price.mjs", "utf8").replaceAll("5000", "3000");
fs.writeFileSync("repo/price.mjs", changed);
git("add price.mjs");
const diff = git("diff --cached");

const clean = (text) => text.replace(/^```\w*\n|```$/g, "").trim();
let message = clean(await ask(`اكتب رسالة حفظ git لهذا التغيير بصيغة Conventional Commits: type(scope): وموضوع من 72 حرفاً على الأكثر، ثم سطر فارغ، ثم متن قصير يقول لماذا. أعِد الرسالة فقط.\n\n${diff}`));
console.log(message);

// الصيغة يفحصها الكود، لا العين.
let problems = lintCommit(message);
console.log(`--- lint: ${problems.length ? problems.join("; ") : "ok"}`);
if (problems.length) {
  const request = `اكتب رسالة حفظ git لهذا التغيير بصيغة Conventional Commits: type(scope): وموضوع من 72 حرفاً على الأكثر، ثم سطر فارغ، ثم متن قصير يقول لماذا. أعِد الرسالة فقط.\n\n${diff}\n\nرسالتك خالفت هذه القواعد. اكتبها من جديد:\n${message}\n${problems.join("\n")}`;
  message = clean(await ask(request));
  problems = lintCommit(message);
  console.log(`--- once more:\n${message}\n--- lint: ${problems.length ? problems.join("; ") : "ok"}`);
}

// إن نجحت الرسالة، فاحفظ بها حفظاً حقيقياً.
if (problems.length === 0) {
  fs.writeFileSync("repo/.message", message);
  git("commit -q -F .message");
  console.log(git("log --oneline"));
}
