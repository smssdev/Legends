import fs from "node:fs";
import {vagueWords} from "./lib/vague.mjs";

for (const file of process.argv.slice(2)) {
  const found = vagueWords(fs.readFileSync(file, "utf8"));
  const list = [...found].map(([word, n]) => `${word} (${n})`).join(", ");
  console.log(`${file}: ${list || "no vague words"}`);
}
