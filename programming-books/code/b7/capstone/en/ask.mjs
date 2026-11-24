import {DOCS} from "./data.mjs";
import {assistant} from "./lib/assistant.mjs";

// The assistant from the command line.
const question = process.argv.slice(2).join(" ");
const {text, cited, ok, problems} = await (await assistant(DOCS))(question, process.env.USER);
console.log(text);
console.log(ok ? `(sources: ${cited.join(", ") || "none"})` : `(not checked: ${problems.join("; ")})`);
