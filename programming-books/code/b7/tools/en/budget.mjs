import fs from "node:fs";
import path from "node:path";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const [folder, budget] = [process.argv[2], Number(process.argv[3])];

const count = (file) => model.tokenize(fs.readFileSync(file, "utf8")).length;

// Choose which files fit in a token budget: smallest first, and say what
// was left out.
const files = fs
  .readdirSync(folder, {recursive: true})
  .map((name) => path.join(folder, name))
  .filter((file) => fs.statSync(file).isFile())
  .map((file) => ({file, tokens: count(file)}))
  .sort((a, b) => a.tokens - b.tokens);

let used = 0;
for (const {file, tokens} of files) {
  const fits = used + tokens <= budget;
  used += fits ? tokens : 0;
  console.log(`${fits ? "in " : "out"} ${String(tokens).padStart(6)}  ${file}`);
}
console.log(`${used} of ${budget} tokens used`);
