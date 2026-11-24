import {execFileSync} from "node:child_process";
import fs from "node:fs";

// Before review: the branch name, every commit message, and the
// description.
const git = (...args) => execFileSync("git", args, {encoding: "utf8"}).trim();
const branch = git("branch", "--show-current");
const messages = git("log", "main..HEAD", "--format=%s").split("\n").filter(Boolean);
const body = fs.readFileSync("PR.md", "utf8");
const sections = [...fs.readFileSync(".github/pull_request_template.md", "utf8").matchAll(/^## .+$/gm)];
const problems = {
  "branch name": /^(fix|feat|docs|chore)\/\d+-[a-z0-9-]+$/.test(branch) ? [] : [branch],
  "commit messages": messages.filter((m) => !/^(feat|fix|docs|refactor|test|chore)(\([a-z-]+\))?: .+/.test(m)),
  "description": [
    ...sections.filter(([s]) => !body.includes(s)).map(([s]) => `missing section: ${s}`),
    ...(/#\d+/.test(body) ? [] : ["does not close an issue"]),
  ],
};
for (const [what, found] of Object.entries(problems)) {
  console.log(`${what.padEnd(16)} ${found.length ? `needs work: ${found.join("; ")}` : "ok"}`);
}
