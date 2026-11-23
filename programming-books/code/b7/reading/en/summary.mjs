import fs from "node:fs";
import path from "node:path";
import {ask} from "./lib/ask.mjs";

// One request per file, so each summary sees only its file.
const folder = process.argv[2];
for (const name of fs.readdirSync(folder, {recursive: true}).sort()) {
  const file = path.join(folder, name);
  if (fs.statSync(file).isFile() && file.endsWith(".js")) {
    const text = fs.readFileSync(file, "utf8");
    const line = await ask(`Describe this file in one line, for a developer new to the project.\n\n${text}`, {maxTokens: 60});
    console.log(`${file}: ${line.split("\n")[0]}`);
  }
}
