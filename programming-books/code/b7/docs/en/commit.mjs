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

const message = (await ask(`Write a git commit message for this change in the Conventional Commits format: type(scope): subject of at most 72 characters, a blank line, then a short body that says why. Return only the message.\n\n${diff}`)).replace(/^```\w*\n|```$/g, "").trim();
console.log(message);

// The format is checked by code, not by eye.
const problems = lintCommit(message);
console.log(`--- lint: ${problems.length ? problems.join("; ") : "ok"}`);

// If the message passes, make the real commit with it.
if (problems.length === 0) {
  fs.writeFileSync("repo/.message", message);
  git("commit -q -F .message");
  console.log(git("log --oneline"));
}
