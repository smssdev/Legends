import {execFileSync} from "node:child_process";
import fs from "node:fs";

// Which files the agent says it changed, against what git says changed.
const said = fs.readFileSync(0, "utf8");
const changed = execFileSync("git", ["diff", "--name-only"], {encoding: "utf8"}).split("\n").filter(Boolean);
const claimed = changed.filter((file) => said.includes(file));
console.log(`claimed: ${claimed.join(", ") || "-"}`);
console.log(`changed in git: ${changed.join(", ")}`);
const missing = changed.filter((file) => !claimed.includes(file));
console.log(`changed but not mentioned: ${missing.join(", ") || "-"}`);
