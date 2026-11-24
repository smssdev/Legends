import fs from "node:fs";
import os from "node:os";
import path from "node:path";

// Mark this folder as trusted, as Claude Code's own message suggests.
const file = path.join(os.homedir(), ".claude.json");
const config = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : {};
config.projects ??= {};
config.projects[process.cwd()] = {...config.projects[process.cwd()], hasTrustDialogAccepted: true};
fs.writeFileSync(file, JSON.stringify(config, null, 2));
console.log(`trusted: ${process.cwd()}`);
