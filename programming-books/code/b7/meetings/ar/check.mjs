import fs from "node:fs";
import {newNumbers} from "./lib/facts.mjs";

// حقائق النص: أرقامه.
const [draft, ...sources] = process.argv.slice(2).map((file) => fs.readFileSync(file, "utf8"));
const invented = newNumbers(draft, ...sources);
console.log(invented.length ? `numbers not in the sources: ${invented.join(", ")}` : "every number has a source");
