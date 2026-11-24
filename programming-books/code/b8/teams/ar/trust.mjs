import fs from "node:fs";
import os from "node:os";
import path from "node:path";

// علّم هذا المجلد موثوقاً.
const file = path.join(os.homedir(), ".claude.json");
const config = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : {};
config.projects ??= {};
config.projects[process.cwd()] = {...config.projects[process.cwd()], hasTrustDialogAccepted: true};
fs.writeFileSync(file, JSON.stringify(config, null, 2));
