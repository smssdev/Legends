import {DOCS} from "./data.mjs";
import {assistant} from "./lib/assistant.mjs";

// المساعد من سطر الأوامر.
const question = process.argv.slice(2).join(" ");
const {text, cited, ok, problems} = await (await assistant(DOCS))(question, process.env.USER);
console.log(text);
console.log(ok ? `(sources: ${cited.join(", ") || "none"})` : `(not checked: ${problems.join("; ")})`);
