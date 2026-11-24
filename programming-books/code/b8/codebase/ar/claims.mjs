import {execFileSync} from "node:child_process";
import fs from "node:fs";

// الملفات التي يقول الوكيل إنه غيّرها، مقابل ما يقول git إنه تغيّر.
const said = fs.readFileSync(0, "utf8");
const changed = execFileSync("git", ["diff", "--name-only"], {encoding: "utf8"}).split("\n").filter(Boolean);
const claimed = changed.filter((file) => said.includes(file));
console.log(`يقول إنه غيّر: ${claimed.join(", ") || "-"}`);
console.log(`تغيّر في git: ${changed.join(", ")}`);
const missing = changed.filter((file) => !claimed.includes(file));
console.log(`تغيّر ولم يُذكر: ${missing.join(", ") || "-"}`);
